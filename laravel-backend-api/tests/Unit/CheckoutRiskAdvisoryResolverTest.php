<?php

namespace Tests\Unit;

use App\Services\CheckoutRiskAdvisoryResolver;
use Tests\TestCase;

class CheckoutRiskAdvisoryResolverTest extends TestCase
{
    public function test_high_traffic_produces_traffic_advisory(): void
    {
        $advisory = app(CheckoutRiskAdvisoryResolver::class)->forPrediction(
            ['risk_level' => 'High', 'risk_score' => 0.85],
            [
                ...$this->baseFeatures(),
                'Traffic_Level' => 'high',
            ],
        );

        $this->assertSame('heavy_traffic', $advisory['advisory_reasons'][0]['code']);
        $this->assertSame(
            'Heavy traffic may delay the rider.',
            $advisory['advisory_reasons'][0]['label'],
        );
    }

    public function test_rainy_and_stormy_weather_produce_weather_advisory(): void
    {
        $resolver = app(CheckoutRiskAdvisoryResolver::class);

        $rainy = $resolver->forPrediction(
            ['risk_level' => 'Medium', 'risk_score' => 0.62],
            [
                ...$this->baseFeatures(),
                'Weather' => 'rainy',
            ],
        );
        $stormy = $resolver->forPrediction(
            ['risk_level' => 'High', 'risk_score' => 0.85],
            [
                ...$this->baseFeatures(),
                'Weather' => 'stormy',
            ],
        );

        $this->assertContains('rainy_weather', array_column($rainy['advisory_reasons'], 'code'));
        $this->assertSame('stormy_weather', $stormy['advisory_reasons'][0]['code']);
        $this->assertSame(
            'Bad weather may slow down delivery.',
            $stormy['advisory_reasons'][0]['label'],
        );
    }

    public function test_long_prep_produces_prep_advisory(): void
    {
        $advisory = app(CheckoutRiskAdvisoryResolver::class)->forPrediction(
            ['risk_level' => 'Medium', 'risk_score' => 0.62],
            [
                ...$this->baseFeatures(),
                'Preparation_Time_min' => 35,
            ],
        );

        $this->assertContains('long_preparation', array_column($advisory['advisory_reasons'], 'code'));
        $this->assertContains(
            'This order may take longer to prepare.',
            array_column($advisory['advisory_reasons'], 'label'),
        );
    }

    public function test_low_risk_returns_friendly_favorable_message(): void
    {
        $advisory = app(CheckoutRiskAdvisoryResolver::class)->forPrediction(
            ['risk_level' => 'Low', 'risk_score' => 0.18],
            $this->baseFeatures(),
        );

        $this->assertSame(
            'Low fulfillment risk. Delivery is expected to proceed normally, but the score is not a guarantee.',
            $advisory['advisory_message'],
        );
        $this->assertSame(
            'Low fulfillment risk. Delivery is expected to proceed normally.',
            $advisory['recommendation'],
        );
        $this->assertSame([], $advisory['advisory_reasons']);
    }

    public function test_high_risk_returns_decision_support_recommendations_without_blocking_checkout(): void
    {
        $advisory = app(CheckoutRiskAdvisoryResolver::class)->forPrediction(
            ['risk_level' => 'High', 'risk_score' => 0.85],
            [
                ...$this->baseFeatures(),
                'Weather' => 'stormy',
                'Traffic_Level' => 'high',
                'Preparation_Time_min' => 35,
                'Courier_Experience_yrs' => 1.0,
            ],
        );

        $this->assertSame(
            'High fulfillment risk detected due to weather, traffic, rider availability, or merchant preparation time. Expect a longer ETA. Consider choosing cashless payment to reduce fulfillment friction. You may continue, but delivery may take longer than usual. Merchant readiness check is recommended before confirming.',
            $advisory['recommendation'],
        );
        $this->assertStringContainsString('Expect a longer ETA.', $advisory['advisory_message']);
        $this->assertStringContainsString('You may continue', $advisory['advisory_message']);
        $this->assertStringContainsString('Merchant readiness check is recommended', $advisory['advisory_message']);
    }

    public function test_medium_risk_returns_softer_eta_and_address_advisory(): void
    {
        $advisory = app(CheckoutRiskAdvisoryResolver::class)->forPrediction(
            ['risk_level' => 'Medium', 'risk_score' => 0.55],
            [
                ...$this->baseFeatures(),
                'Traffic_Level' => 'medium',
            ],
        );

        $this->assertSame(
            'Medium fulfillment risk. Check ETA and address details before placing the order.',
            $advisory['recommendation'],
        );
        $this->assertStringContainsString('Check the ETA', $advisory['advisory_message']);
        $this->assertStringContainsString('confirm the address details', $advisory['advisory_message']);
    }

    private function baseFeatures(): array
    {
        return [
            'Distance_km' => 2.8,
            'Weather' => 'clear',
            'Traffic_Level' => 'low',
            'Time_of_Day' => 'afternoon',
            'Vehicle_Type' => 'motorcycle',
            'Preparation_Time_min' => 15,
            'Courier_Experience_yrs' => 3.5,
        ];
    }
}
