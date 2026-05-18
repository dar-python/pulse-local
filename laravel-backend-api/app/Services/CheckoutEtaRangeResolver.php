<?php

namespace App\Services;

class CheckoutEtaRangeResolver
{
    public function forPrediction(array $prediction): string
    {
        return match (strtolower((string) ($prediction['risk_level'] ?? ''))) {
            'low' => '20-30 min',
            'medium' => '30-40 min',
            'high' => '40-55 min',
            default => '30-45 min',
        };
    }
}
