<?php

namespace App\Http\Controllers;

use App\Http\Requests\CheckoutRiskRequest;
use App\Services\CheckoutEtaRangeResolver;
use App\Services\CheckoutPredictionFeatureBuilder;
use App\Services\MLServiceClient;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Throwable;

class CheckoutRiskController extends Controller
{
    public function __invoke(
        CheckoutRiskRequest $request,
        CheckoutPredictionFeatureBuilder $featureBuilder,
        MLServiceClient $mlServiceClient,
        CheckoutEtaRangeResolver $etaRangeResolver
    ): JsonResponse
    {
        $modelFeatures = [];

        try {
            $modelFeatures = $featureBuilder->build($request->validated());
            $prediction = $mlServiceClient->calculateCheckoutRisk($modelFeatures);
            $prediction['eta_range'] = $etaRangeResolver->forPrediction($prediction);

            return response()->json([
                'success' => true,
                'source' => 'ml-service',
                'data' => $prediction,
            ]);
        } catch (Throwable $e) {
            $mlServiceUrl = (string) config('services.ml_service.url');
            $predictionUrl = rtrim($mlServiceUrl, '/').'/predict';

            Log::warning('Checkout risk ML service fallback triggered.', [
                'exception_class' => $e::class,
                'exception_message' => $e->getMessage(),
                'ml_service_url' => $mlServiceUrl,
                'prediction_url' => $predictionUrl,
                'feature_keys' => array_keys($modelFeatures),
            ]);

            return response()->json([
                'success' => true,
                'source' => (string) config('services.checkout_risk.fallback_source'),
                'data' => [
                    'risk_score' => round((float) config('services.checkout_risk.fallback_score'), 2),
                    'risk_level' => (string) config('services.checkout_risk.fallback_level'),
                    'recommendation' => (string) config('services.checkout_risk.fallback_recommendation'),
                    'eta_range' => '30-45 min',
                ],
            ]);
        }
    }
}
