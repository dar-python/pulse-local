<?php

namespace App\Http\Controllers;

use App\Http\Requests\CheckoutRiskRequest;
use App\Services\MLServiceClient;
use Illuminate\Http\JsonResponse;
use Throwable;

class CheckoutRiskController extends Controller
{
    public function __invoke(CheckoutRiskRequest $request, MLServiceClient $mlServiceClient): JsonResponse
    {
        try {
            return response()->json([
                'success' => true,
                'source' => 'ml-service',
                'data' => $mlServiceClient->calculateCheckoutRisk($request->validated()),
            ]);
        } catch (Throwable) {
            return response()->json([
                'success' => true,
                'source' => 'fallback',
                'data' => [
                    'risk_score' => 0.50,
                    'risk_level' => 'Unknown',
                    'recommendation' => 'Standard checkout allowed. Risk service unavailable.',
                ],
            ]);
        }
    }
}
