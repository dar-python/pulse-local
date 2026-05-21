<?php

namespace App\Http\Controllers;

use App\Http\Requests\CheckoutRiskRequest;
use App\Services\CheckoutRiskAdvisoryResolver;
use App\Services\CheckoutEtaRangeResolver;
use App\Services\CheckoutPredictionFeatureBuilder;
use App\Services\MLServiceClient;
use App\Services\Weather\WeatherServiceInterface;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Throwable;

class CheckoutRiskController extends Controller
{
    public function __invoke(
        CheckoutRiskRequest $request,
        CheckoutPredictionFeatureBuilder $featureBuilder,
        MLServiceClient $mlServiceClient,
        CheckoutEtaRangeResolver $etaRangeResolver,
        CheckoutRiskAdvisoryResolver $advisoryResolver,
        WeatherServiceInterface $weatherService
    ): JsonResponse
    {
        $modelFeatures = [];
        $weather = null;
        $checkoutContext = $request->validated();

        try {
            $weather = $weatherService->currentForCheckout($checkoutContext);
            $modelFeatures = $featureBuilder->build($checkoutContext, $weather->category);
            $prediction = $mlServiceClient->calculateCheckoutRisk($modelFeatures);
            $prediction['eta_range'] = $etaRangeResolver->forPrediction($prediction);
            $prediction = [
                ...$prediction,
                ...$advisoryResolver->forPrediction($prediction, $modelFeatures),
                'weather' => $weather->toArray(),
            ];

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

            $fallbackPrediction = [
                'risk_score' => round((float) config('services.checkout_risk.fallback_score'), 2),
                'risk_level' => (string) config('services.checkout_risk.fallback_level'),
                'recommendation' => (string) config('services.checkout_risk.fallback_recommendation'),
                'eta_range' => '30-45 min',
            ];
            $fallbackPrediction = [
                ...$fallbackPrediction,
                ...$advisoryResolver->forPrediction($fallbackPrediction, $modelFeatures),
                'weather' => $weather?->toArray(),
            ];

            return response()->json([
                'success' => true,
                'source' => (string) config('services.checkout_risk.fallback_source'),
                'data' => $fallbackPrediction,
            ]);
        }
    }
}
