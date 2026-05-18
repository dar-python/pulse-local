<?php

namespace App\Http\Controllers;

use App\Http\Requests\CartCheckoutRequest;
use App\Services\FoodPulseLocalData;
use Illuminate\Http\JsonResponse;

class FoodPulseController extends Controller
{
    public function restaurants(FoodPulseLocalData $foodPulseData): JsonResponse
    {
        return $this->localDataResponse($foodPulseData->restaurants());
    }

    public function menu(int $restaurant, FoodPulseLocalData $foodPulseData): JsonResponse
    {
        $restaurantData = $foodPulseData->restaurant($restaurant);

        if ($restaurantData === null) {
            return $this->notFoundResponse('Restaurant not found.');
        }

        return $this->localDataResponse([
            'restaurant' => $restaurantData,
            'items' => $foodPulseData->menuItems($restaurant),
        ]);
    }

    public function checkout(
        CartCheckoutRequest $request,
        FoodPulseLocalData $foodPulseData
    ): JsonResponse {
        return $this->localDataResponse(
            $foodPulseData->checkout($request->validated())
        );
    }

    public function orderConfirmation(
        string $orderNumber,
        FoodPulseLocalData $foodPulseData
    ): JsonResponse {
        $order = $foodPulseData->orderConfirmation($orderNumber);

        if ($order === null) {
            return $this->notFoundResponse('Order confirmation not found.');
        }

        return $this->localDataResponse($order);
    }

    private function localDataResponse(array $data): JsonResponse
    {
        return response()->json([
            'success' => true,
            'source' => FoodPulseLocalData::SOURCE,
            'data' => $data,
        ]);
    }

    private function notFoundResponse(string $message): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
        ], 404);
    }
}
