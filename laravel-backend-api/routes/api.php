<?php

use App\Http\Controllers\CheckoutRiskController;
use App\Http\Controllers\FoodPulseController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'laravel-api',
    ]);
});

Route::post('/checkout/risk', CheckoutRiskController::class);

Route::get('/restaurants', [FoodPulseController::class, 'restaurants']);
Route::get('/restaurants/{restaurant}/menu', [FoodPulseController::class, 'menu'])
    ->whereNumber('restaurant');
Route::post('/cart/checkout', [FoodPulseController::class, 'checkout']);
Route::get('/orders/{orderNumber}/confirmation', [FoodPulseController::class, 'orderConfirmation']);
