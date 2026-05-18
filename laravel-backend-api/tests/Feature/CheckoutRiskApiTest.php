<?php

namespace Tests\Feature;

use App\Services\MLServiceClient;
use Carbon\Carbon;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Mockery;
use RuntimeException;
use Tests\TestCase;

class CheckoutRiskApiTest extends TestCase
{
    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_checkout_risk_endpoint_builds_model_features_and_returns_ml_service_result(): void
    {
        Carbon::setTestNow('2026-05-18 18:15:00');
        config(['services.ml_service.url' => 'http://ml-service:8001']);

        Http::fake([
            'http://ml-service:8001/predict' => Http::response([
                'risk_score' => 0.85,
                'risk_level' => 'High',
                'recommendation' => 'High fulfillment risk. Adjust ETA and notify merchant.',
            ]),
        ]);

        $response = $this->postJson('/api/checkout/risk', $this->validPayload());

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'source' => 'ml-service',
                'data' => [
                    'risk_score' => 0.85,
                    'risk_level' => 'High',
                    'recommendation' => 'High fulfillment risk. Adjust ETA and notify merchant.',
                    'eta_range' => '40-55 min',
                ],
            ]);

        $this->assertSame(['success', 'source', 'data'], array_keys($response->json()));
        $this->assertSame(
            ['risk_score', 'risk_level', 'recommendation', 'eta_range'],
            array_keys($response->json('data'))
        );

        Http::assertSent(fn ($request) => $request->url() === 'http://ml-service:8001/predict'
            && $request['Distance_km'] === 5.0
            && $request['Weather'] === 'rainy'
            && $request['Traffic_Level'] === 'medium'
            && $request['Time_of_Day'] === 'evening'
            && $request['Vehicle_Type'] === 'motorcycle'
            && $request['Preparation_Time_min'] === 25
            && $request['Courier_Experience_yrs'] === 2.0
            && ! isset($request['rider_to_order_ratio'])
            && ! isset($request['merchant_prep_time']));
    }

    public function test_checkout_risk_endpoint_returns_fallback_when_ml_service_is_unavailable(): void
    {
        Carbon::setTestNow('2026-05-18 18:15:00');
        config([
            'app.debug' => false,
            'services.ml_service.url' => 'http://ml-service:8001',
        ]);

        Http::fake(fn () => throw new ConnectionException('ML service unavailable'));

        $response = $this->postJson('/api/checkout/risk', $this->validPayload());

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'source' => 'laravel-fallback',
                'data' => [
                    'risk_score' => 0.50,
                    'risk_level' => 'Unknown',
                    'recommendation' => 'Prediction service unavailable. Proceed with standard checkout risk.',
                    'eta_range' => '30-45 min',
                ],
            ])
            ->assertJsonMissingPath('debug');

        $this->assertSame(['success', 'source', 'data'], array_keys($response->json()));
    }

    public function test_checkout_risk_fallback_logs_exception_without_exposing_debug_internals(): void
    {
        Carbon::setTestNow('2026-05-18 18:15:00');
        config([
            'app.debug' => true,
            'services.ml_service.url' => 'http://ml-service:8001',
        ]);

        Log::shouldReceive('warning')
            ->once()
            ->with(
                'Checkout risk ML service fallback triggered.',
                Mockery::on(fn (array $context) => $context['exception_class'] === RuntimeException::class
                    && str_contains($context['exception_message'], 'ML service returned HTTP 500')
                    && $context['ml_service_url'] === 'http://ml-service:8001'
                    && $context['prediction_url'] === 'http://ml-service:8001/predict'
                    && $context['feature_keys'] === [
                        'Distance_km',
                        'Weather',
                        'Traffic_Level',
                        'Time_of_Day',
                        'Vehicle_Type',
                        'Preparation_Time_min',
                        'Courier_Experience_yrs',
                    ])
            );

        Http::fake([
            'http://ml-service:8001/predict' => Http::response(['error' => 'unavailable'], 500),
        ]);

        $response = $this->postJson('/api/checkout/risk', $this->validPayload());

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'source' => 'laravel-fallback',
                'data' => [
                    'risk_score' => 0.50,
                    'risk_level' => 'Unknown',
                    'recommendation' => 'Prediction service unavailable. Proceed with standard checkout risk.',
                    'eta_range' => '30-45 min',
                ],
            ])
            ->assertJsonMissingPath('debug')
            ->assertJsonMissingPath('exception')
            ->assertJsonMissingPath('trace')
            ->assertJsonMissingPath('ml_service_url')
            ->assertJsonMissingPath('prediction_url');

        $this->assertSame(['success', 'source', 'data'], array_keys($response->json()));
    }

    public function test_checkout_risk_endpoint_returns_fallback_when_ml_service_times_out(): void
    {
        Carbon::setTestNow('2026-05-18 18:15:00');
        config([
            'app.debug' => true,
            'services.ml_service.url' => 'http://ml-service:8001',
            'services.ml_service.timeout' => 1,
        ]);

        Http::fake(fn () => throw new ConnectionException('cURL error 28: Operation timed out'));

        $response = $this->postJson('/api/checkout/risk', $this->validPayload());

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'source' => 'laravel-fallback',
                'data' => [
                    'risk_score' => 0.50,
                    'risk_level' => 'Unknown',
                    'recommendation' => 'Prediction service unavailable. Proceed with standard checkout risk.',
                    'eta_range' => '30-45 min',
                ],
            ])
            ->assertJsonMissingPath('debug');
    }

    public function test_ml_service_client_posts_generated_model_features_to_configured_predict_endpoint(): void
    {
        config(['services.ml_service.url' => 'http://ml-service:8001']);

        $features = [
            'Distance_km' => 2.8,
            'Weather' => 'clear',
            'Traffic_Level' => 'low',
            'Time_of_Day' => 'afternoon',
            'Vehicle_Type' => 'motorcycle',
            'Preparation_Time_min' => 15,
            'Courier_Experience_yrs' => 3.5,
        ];

        Http::fake([
            'http://ml-service:8001/predict' => Http::response([
                'risk_score' => 0.28,
                'risk_level' => 'Low',
                'recommendation' => 'Low fulfillment risk. Proceed with normal checkout.',
            ]),
        ]);

        app(MLServiceClient::class)->calculateCheckoutRisk($features);

        Http::assertSent(fn ($request) => $request->url() === 'http://ml-service:8001/predict'
            && $request->data() === $features);
    }

    public function test_different_valid_checkout_contexts_produce_different_ml_payloads(): void
    {
        Carbon::setTestNow('2026-05-18 18:15:00');
        config(['services.ml_service.url' => 'http://ml-service:8001']);

        Http::fake([
            'http://ml-service:8001/predict' => Http::response([
                'risk_score' => 0.50,
                'risk_level' => 'Medium',
                'recommendation' => 'Medium fulfillment risk. Show advisory and realistic ETA.',
            ]),
        ]);

        $this->postJson('/api/checkout/risk', $this->validPayload())->assertOk();
        $this->postJson('/api/checkout/risk', $this->jollibeePayload())->assertOk();

        $payloads = Http::recorded()
            ->map(fn (array $record): array => $record[0]->data())
            ->all();

        $this->assertCount(2, $payloads);
        $this->assertNotSame($payloads[0], $payloads[1]);
        $this->assertSame('rainy', $payloads[0]['Weather']);
        $this->assertSame('clear', $payloads[1]['Weather']);
        $this->assertSame(25, $payloads[0]['Preparation_Time_min']);
        $this->assertSame(15, $payloads[1]['Preparation_Time_min']);
    }

    public function test_checkout_risk_endpoint_validates_required_checkout_context(): void
    {
        $response = $this->postJson('/api/checkout/risk', []);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors([
                'restaurant_id',
                'items',
                'delivery_address',
                'payment_method',
            ])
            ->assertJsonMissingPath('exception')
            ->assertJsonMissingPath('trace');

        $this->assertSame(['success', 'message', 'errors'], array_keys($response->json()));
    }

    public function test_checkout_risk_endpoint_rejects_invalid_checkout_context_values(): void
    {
        $response = $this->postJson('/api/checkout/risk', [
            ...$this->validPayload(),
            'restaurant_id' => 999,
            'items' => [
                [
                    'id' => 1,
                    'name' => 'Pork Sinigang',
                    'category' => 'Bestsellers',
                    'quantity' => 0,
                    'unit_price' => -1,
                ],
            ],
            'payment_method' => 'wallet',
        ]);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors([
                'restaurant_id',
                'items.0.quantity',
                'items.0.unit_price',
                'payment_method',
            ])
            ->assertJsonMissingPath('exception')
            ->assertJsonMissingPath('trace');
    }

    private function validPayload(): array
    {
        return [
            'restaurant_id' => 1,
            'restaurant_slug' => 'tambayan-grill',
            'items' => [
                [
                    'id' => 1,
                    'name' => 'Pork Sinigang',
                    'category' => 'Bestsellers',
                    'quantity' => 1,
                    'unit_price' => 185,
                ],
                [
                    'id' => 2,
                    'name' => 'Chicken Inasal',
                    'category' => 'Bestsellers',
                    'quantity' => 1,
                    'unit_price' => 155,
                ],
            ],
            'delivery_address' => [
                'label' => 'Marasbaras, Tacloban City',
                'notes' => 'Zone 7, Leyte, Philippines',
            ],
            'payment_method' => 'cod',
            'subtotal' => 340,
            'total_quantity' => 2,
        ];
    }

    private function jollibeePayload(): array
    {
        return [
            'restaurant_id' => 2,
            'restaurant_slug' => 'jollibee-express',
            'items' => [
                [
                    'id' => 6,
                    'name' => 'Chickenjoy Meal',
                    'category' => 'Bestsellers',
                    'quantity' => 1,
                    'unit_price' => 149,
                ],
            ],
            'delivery_address' => [
                'label' => 'Tacloban City',
            ],
            'payment_method' => 'gcash',
            'subtotal' => 149,
            'total_quantity' => 1,
        ];
    }
}
