<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin array<string, mixed>
 */
class ModelMetadataResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'model_name' => $this->resource['model_name'],
            'model_type' => $this->resource['model_type'],
            'target_column' => $this->resource['target_column'],
            'features' => $this->resource['features'],
            'numeric_features' => $this->resource['numeric_features'],
            'categorical_features' => $this->resource['categorical_features'],
            'risk_thresholds' => $this->resource['risk_thresholds'],
            'test_metrics' => $this->resource['test_metrics'],
            'cross_validation' => $this->resource['cross_validation'],
            'ml_service' => [
                'status' => 'available',
            ],
        ];
    }
}
