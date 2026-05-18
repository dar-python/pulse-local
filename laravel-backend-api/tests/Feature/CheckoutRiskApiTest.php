<?php

namespace Tests\Feature;

use App\Services\MLServiceClient;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Mockery;
use RuntimeException;
use Tests\TestCase;

class CheckoutRiskApiTest extends TestCase
{
    public function test_checkout_risk_endpoint_returns_ml_service_result(): void
    {
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
                ],
            ]);

        $this->assertSame(['success', 'source', 'data'], array_keys($response->json()));
        $this->assertSame(
            ['risk_score', 'risk_level', 'recommendation'],
            array_keys($response->json('data'))
        );

        Http::assertSent(fn ($request) => $request->url() === 'http://ml-service:8001/predict'
            && $request['rider_to_order_ratio'] === 0.45
            && $request['merchant_prep_time'] === 25
            && $request['traffic_corridor_intensity'] === 'high'
            && $request['address_complexity'] === 'medium'
            && $request['weather_category'] === 'rainy'
            && $request['delivery_distance_km'] === 4.2
            && $request['payment_method'] === 'cod');
    }

    public function test_checkout_risk_endpoint_returns_fallback_when_ml_service_is_unavailable(): void
    {
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
                ],
            ])
            ->assertJsonMissingPath('debug');

        $this->assertSame(['success', 'source', 'data'], array_keys($response->json()));
    }

    public function test_checkout_risk_fallback_logs_exception_without_exposing_debug_internals(): void
    {
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
                    && $context['prediction_url'] === 'http://ml-service:8001/predict')
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
                ],
            ])
            ->assertJsonMissingPath('debug');
    }

    public function test_ml_service_client_posts_to_configured_predict_endpoint(): void
    {
        config(['services.ml_service.url' => 'http://ml-service:8001']);

        Http::fake([
            'http://ml-service:8001/predict' => Http::response([
                'risk_score' => 0.85,
                'risk_level' => 'High',
                'recommendation' => 'High fulfillment risk. Adjust ETA and notify merchant.',
            ]),
        ]);

        app(MLServiceClient::class)->calculateCheckoutRisk($this->validPayload());

        Http::assertSent(fn ($request) => $request->url() === 'http://ml-service:8001/predict');
    }

    public function test_checkout_risk_endpoint_validates_required_checkout_features(): void
    {
        $response = $this->postJson('/api/checkout/risk', []);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors([
                'rider_to_order_ratio',
                'merchant_prep_time',
                'traffic_corridor_intensity',
                'weather_category',
                'delivery_distance_km',
                'address_complexity',
                'payment_method',
            ])
            ->assertJsonMissingPath('exception')
            ->assertJsonMissingPath('trace');

        $this->assertSame(['success', 'message', 'errors'], array_keys($response->json()));
    }

    public function test_checkout_risk_endpoint_rejects_values_not_supported_by_fastapi(): void
    {
        $response = $this->postJson('/api/checkout/risk', [
            ...$this->validPayload(),
            'merchant_prep_time' => 0,
            'weather_category' => 'cloudy',
            'payment_method' => 'wallet',
        ]);

        $response->assertUnprocessable()
            ->assertJson([
                'success' => false,
                'message' => 'Validation failed.',
            ])
            ->assertJsonValidationErrors([
                'merchant_prep_time',
                'weather_category',
                'payment_method',
            ])
            ->assertJsonMissingPath('exception')
            ->assertJsonMissingPath('trace');
    }

    private function validPayload(): array
    {
        return [
            'rider_to_order_ratio' => 0.45,
            'merchant_prep_time' => 25,
            'traffic_corridor_intensity' => 'high',
            'weather_category' => 'rainy',
            'delivery_distance_km' => 4.2,
            'address_complexity' => 'medium',
            'payment_method' => 'cod',
        ];
    }
}
