<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

class MLServiceClient
{
    public function calculateCheckoutRisk(array $payload): array
    {
        $response = Http::acceptJson()
            ->asJson()
            ->timeout(3)
            ->post($this->predictionUrl(), $payload);

        if ($response->failed()) {
            throw new RuntimeException('ML service returned an unsuccessful response.');
        }

        return $this->normalizeRiskResult($response->json());
    }

    private function predictionUrl(): string
    {
        return rtrim((string) config('services.ml.url'), '/').'/predict';
    }

    private function normalizeRiskResult(mixed $payload): array
    {
        if (! is_array($payload)) {
            throw new RuntimeException('ML service response was not valid JSON.');
        }

        $data = isset($payload['data']) && is_array($payload['data'])
            ? $payload['data']
            : $payload;

        if (! isset($data['risk_score']) || ! is_numeric($data['risk_score'])) {
            throw new RuntimeException('ML service response is missing risk_score.');
        }

        return [
            'risk_score' => round((float) $data['risk_score'], 2),
            'risk_level' => (string) ($data['risk_level'] ?? 'Unknown'),
            'recommendation' => (string) ($data['recommendation'] ?? 'No recommendation returned.'),
        ];
    }
}
