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

        Http::assertSent(fn ($request) => $request->url() === 'http://ml-service:8001/predict'
            && $request['rider_to_order_ratio'] === 0.45
            && $request['merchant_prep_time'] === 25
            && $request['traffic_level'] === 'heavy'
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
    }

    public function test_checkout_risk_fallback_logs_exception_and_returns_debug_when_enabled(): void
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
                    && str_contains($context['exception_message'], 'unsuccessful response')
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
                'debug' => [
                    'exception' => RuntimeException::class,
                    'message' => 'ML service returned an unsuccessful response.',
                    'ml_service_url' => 'http://ml-service:8001',
                    'prediction_url' => 'http://ml-service:8001/predict',
                ],
            ]);
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
            ->assertJsonValidationErrors([
                'rider_to_order_ratio',
                'merchant_prep_time',
                'traffic_level',
                'weather_category',
                'delivery_distance_km',
                'payment_method',
            ]);
    }

    public function test_checkout_risk_endpoint_rejects_values_not_supported_by_fastapi(): void
    {
        $response = $this->postJson('/api/checkout/risk', [
            ...$this->validPayload(),
            'weather_category' => 'cloudy',
            'payment_method' => 'wallet',
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors([
                'weather_category',
                'payment_method',
            ]);
    }

    private function validPayload(): array
    {
        return [
            'rider_to_order_ratio' => 0.45,
            'merchant_prep_time' => 25,
            'traffic_level' => 'heavy',
            'weather_category' => 'rainy',
            'delivery_distance_km' => 4.2,
            'payment_method' => 'cod',
        ];
    }
}
