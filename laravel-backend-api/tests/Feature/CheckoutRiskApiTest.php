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
    protected function setUp(): void
    {
        parent::setUp();

        config(['services.weatherapi.key' => null]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }

    public function test_checkout_risk_endpoint_builds_model_features_and_returns_ml_service_result(): void
    {
        Carbon::setTestNow('2026-05-18 18:15:00');
        config([
            'services.ml_service.url' => 'http://ml-service:8001',
            'services.weatherapi.key' => 'test-weather-key',
        ]);

        Http::fake([
            'https://api.weatherapi.com/v1/current.json*' => Http::response(
                $this->weatherApiPayload(1003, 'Partly cloudy')
            ),
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
                    'recommendation' => 'High fulfillment risk detected due to weather, traffic, rider availability, or merchant preparation time. Expect a longer ETA. Consider choosing cashless payment to reduce fulfillment friction. You may continue, but delivery may take longer than usual. Merchant readiness check is recommended before confirming.',
                    'eta_range' => '40-55 min',
                    'weather' => [
                        'category' => 'clear',
                        'condition_text' => 'Partly cloudy',
                        'condition_code' => 1003,
                        'source' => 'weatherapi',
                    ],
                ],
            ]);

        $this->assertSame(['success', 'source', 'data'], array_keys($response->json()));
        $this->assertSame(
            [
                'risk_score',
                'risk_level',
                'recommendation',
                'eta_range',
                'advisory_message',
                'advisory_reasons',
                'weather',
            ],
            array_keys($response->json('data'))
        );

        Http::assertSent(fn ($request) => $request->url() === 'http://ml-service:8001/predict'
            && $request['Distance_km'] === 5.0
            && $request['Weather'] === 'clear'
            && $request['Traffic_Level'] === 'medium'
            && $request['Time_of_Day'] === 'evening'
            && $request['Vehicle_Type'] === 'motorcycle'
            && $request['Preparation_Time_min'] === 25
            && $request['Courier_Experience_yrs'] === 2.0
            && ! isset($request['rider_to_order_ratio'])
            && ! isset($request['merchant_prep_time']));
    }

    public function test_checkout_ignores_client_weather_and_sends_laravel_resolved_weather_to_ml(): void
    {
        Carbon::setTestNow('2026-05-18 18:15:00');
        config([
            'services.ml_service.url' => 'http://ml-service:8001',
            'services.weatherapi.key' => 'fake-weather-key-that-must-not-leak',
        ]);

        Http::fake([
            'https://api.weatherapi.com/v1/current.json*' => Http::response(
                $this->weatherApiPayload(1000, 'Sunny')
            ),
            'http://ml-service:8001/predict' => Http::response([
                'risk_score' => 0.42,
                'risk_level' => 'Medium',
                'recommendation' => 'Medium fulfillment risk. Show ETA.',
            ]),
        ]);

        $response = $this->postJson('/api/checkout/risk', [
            ...$this->validPayload(),
            'weather_category' => 'rainy',
            'delivery_latitude' => 14.5995,
            'delivery_longitude' => 120.9842,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.weather.category', 'clear')
            ->assertJsonPath('data.weather.condition_text', 'Sunny')
            ->assertJsonPath('data.weather.condition_code', 1000)
            ->assertJsonPath('data.weather.source', 'weatherapi');

        $this->assertStringNotContainsString(
            'fake-weather-key-that-must-not-leak',
            $response->getContent()
        );

        Http::assertSent(fn ($request) => $request->url() === 'http://ml-service:8001/predict'
            && $request['Weather'] === 'clear');
    }

    public function test_checkout_weatherapi_failure_uses_clear_fallback_without_exposing_api_key(): void
    {
        Carbon::setTestNow('2026-05-18 18:15:00');
        config([
            'services.ml_service.url' => 'http://ml-service:8001',
            'services.weatherapi.key' => 'fake-weather-key-that-must-not-leak',
        ]);

        Log::shouldReceive('warning')
            ->once()
            ->with(
                'WeatherAPI current weather fallback triggered.',
                Mockery::on(fn (array $context): bool => ! str_contains(
                    json_encode($context, JSON_THROW_ON_ERROR),
                    'fake-weather-key-that-must-not-leak'
                ))
            );

        Http::fake(function ($request) {
            if (str_contains($request->url(), 'current.json')) {
                throw new ConnectionException(
                    'Connection failed for fake-weather-key-that-must-not-leak'
                );
            }

            return Http::response([
                'risk_score' => 0.42,
                'risk_level' => 'Medium',
                'recommendation' => 'Medium fulfillment risk. Show ETA.',
            ]);
        });

        $response = $this->postJson('/api/checkout/risk', $this->validPayload());

        $response->assertOk()
            ->assertJsonPath('data.weather.category', 'clear')
            ->assertJsonPath('data.weather.source', 'fallback');

        $this->assertStringNotContainsString(
            'fake-weather-key-that-must-not-leak',
            $response->getContent()
        );

        Http::assertSent(fn ($request) => $request->url() === 'http://ml-service:8001/predict'
            && $request['Weather'] === 'clear');
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

    public function test_checkout_risk_response_keeps_original_fields_with_safe_advisory_metadata(): void
    {
        Carbon::setTestNow('2026-05-18 21:15:00');
        config(['services.ml_service.url' => 'http://ml-service:8001']);

        Http::fake([
            'http://ml-service:8001/predict' => Http::response([
                'risk_score' => 0.85,
                'risk_level' => 'High',
                'recommendation' => 'High fulfillment risk. Adjust ETA and notify merchant.',
            ]),
        ]);

        $response = $this->postJson('/api/checkout/risk', [
            ...$this->validPayload(),
            'restaurant_slug' => 'chao-fan-house',
            'total_quantity' => 5,
            'delivery_address' => [
                'label' => 'V&G Subdivision Extension',
                'notes' => 'Near gate',
            ],
        ]);

        $response->assertOk()
            ->assertJsonPath('data.risk_score', 0.85)
            ->assertJsonPath('data.risk_level', 'High')
            ->assertJsonPath('data.eta_range', '40-55 min')
            ->assertJsonPath(
                'data.advisory_message',
                'High fulfillment risk detected due to weather, traffic, rider availability, or merchant preparation time. Expect a longer ETA. Consider choosing cashless payment to reduce fulfillment friction. You may continue, but delivery may take longer than usual. Merchant readiness check is recommended before confirming.'
            )
            ->assertJsonMissingPath('data.model_features')
            ->assertJsonMissingPath('data.feature_keys');

        $this->assertSame(['success', 'source', 'data'], array_keys($response->json()));
        $this->assertSame(
            [
                'risk_score',
                'risk_level',
                'recommendation',
                'eta_range',
                'advisory_message',
                'advisory_reasons',
                'weather',
            ],
            array_keys($response->json('data'))
        );
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
        $this->assertSame('clear', $payloads[0]['Weather']);
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

    public function test_checkout_risk_endpoint_rejects_invalid_optional_prediction_context(): void
    {
        $response = $this->postJson('/api/checkout/risk', [
            ...$this->validPayload(),
            'delivery_latitude' => 95,
            'delivery_longitude' => -190,
            'delivery_distance_km' => -1,
            'merchant_prep_time' => 121,
            'rider_to_order_ratio' => 2.5,
            'traffic_corridor_intensity' => 'gridlocked',
            'weather_category' => 'hailing',
            'address_complexity' => 'maze',
        ]);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors([
                'delivery_latitude',
                'delivery_longitude',
                'delivery_distance_km',
                'merchant_prep_time',
                'rider_to_order_ratio',
                'traffic_corridor_intensity',
                'weather_category',
                'address_complexity',
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

    private function weatherApiPayload(int $code, string $text): array
    {
        return [
            'location' => [
                'tz_id' => 'Asia/Manila',
            ],
            'current' => [
                'last_updated_epoch' => 1779330600,
                'temp_c' => 30.2,
                'precip_mm' => 0,
                'condition' => [
                    'text' => $text,
                    'code' => $code,
                ],
            ],
        ];
    }
}
