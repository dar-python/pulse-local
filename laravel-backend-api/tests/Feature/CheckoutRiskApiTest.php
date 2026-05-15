<?php

namespace Tests\Feature;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class CheckoutRiskApiTest extends TestCase
{
    public function test_checkout_risk_endpoint_returns_ml_service_result(): void
    {
        config(['services.ml.url' => 'http://ml-service:8001']);

        Http::fake([
            'http://ml-service:8001/predict' => Http::response([
                'risk_score' => 0.72,
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
                    'risk_score' => 0.72,
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
        config(['services.ml.url' => 'http://ml-service:8001']);

        Http::fake(fn () => throw new ConnectionException('ML service unavailable'));

        $response = $this->postJson('/api/checkout/risk', $this->validPayload());

        $response->assertOk()
            ->assertJson([
                'success' => true,
                'source' => 'fallback',
                'data' => [
                    'risk_score' => 0.50,
                    'risk_level' => 'Unknown',
                    'recommendation' => 'Standard checkout allowed. Risk service unavailable.',
                ],
            ]);
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
