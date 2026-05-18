<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\ModelMetadataResource;
use App\Services\MlModelMetadataService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Throwable;

class ModelMetadataController extends Controller
{
    public function __invoke(MlModelMetadataService $metadataService): ModelMetadataResource|JsonResponse
    {
        try {
            return new ModelMetadataResource($metadataService->fetch());
        } catch (Throwable $exception) {
            Log::warning('Admin model metadata fetch failed.', [
                'exception_class' => $exception::class,
                'exception_message' => $exception->getMessage(),
                'ml_service_url' => (string) config('services.ml_service.url'),
                'metadata_url' => $metadataService->metadataUrl(),
            ]);

            return response()->json([
                'data' => [
                    'ml_service' => [
                        'status' => 'unavailable',
                    ],
                ],
                'message' => 'Model metadata is temporarily unavailable.',
            ], 503);
        }
    }
}
