<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

class MlModelMetadataService
{
    /**
     * @return array<string, mixed>
     */
    public function fetch(): array
    {
        $response = Http::acceptJson()
            ->timeout((int) config('services.ml_service.timeout', 2))
            ->get($this->metadataUrl());

        if ($response->failed()) {
            throw new RuntimeException(sprintf(
                'ML service metadata endpoint returned HTTP %s.',
                $response->status()
            ));
        }

        return $this->normalizeMetadata($response->json());
    }

    public function metadataUrl(): string
    {
        return rtrim((string) config('services.ml_service.url'), '/').'/metadata';
    }

    /**
     * @return array<string, mixed>
     */
    private function normalizeMetadata(mixed $payload): array
    {
        if (! is_array($payload)) {
            throw new RuntimeException('ML service metadata response was not valid JSON.');
        }

        $data = isset($payload['data']) && is_array($payload['data'])
            ? $payload['data']
            : $payload;

        foreach ($this->requiredKeys() as $key) {
            if (! array_key_exists($key, $data)) {
                throw new RuntimeException("ML service metadata response is missing {$key}.");
            }
        }

        return [
            'model_name' => (string) $data['model_name'],
            'model_type' => (string) $data['model_type'],
            'target_column' => (string) $data['target_column'],
            'features' => array_values((array) $data['features']),
            'numeric_features' => array_values((array) $data['numeric_features']),
            'categorical_features' => array_values((array) $data['categorical_features']),
            'risk_thresholds' => (array) $data['risk_thresholds'],
            'test_metrics' => (array) $data['test_metrics'],
            'cross_validation' => (array) $data['cross_validation'],
        ];
    }

    /**
     * @return list<string>
     */
    private function requiredKeys(): array
    {
        return [
            'model_name',
            'model_type',
            'target_column',
            'features',
            'numeric_features',
            'categorical_features',
            'risk_thresholds',
            'test_metrics',
            'cross_validation',
        ];
    }
}
