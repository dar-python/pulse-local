<?php

use App\Http\Controllers\CheckoutRiskController;
use App\Http\Controllers\FoodPulseController;
use App\Http\Controllers\MobileAuthController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'laravel-api',
    ]);
});

Route::post('/checkout/risk', CheckoutRiskController::class);

Route::post('/auth/register', [MobileAuthController::class, 'register']);
Route::post('/auth/login', [MobileAuthController::class, 'login']);
Route::put('/auth/profile', [MobileAuthController::class, 'updateProfile']);
Route::put('/auth/password', [MobileAuthController::class, 'updatePassword']);

Route::get('/restaurants', [FoodPulseController::class, 'restaurants']);
Route::get('/restaurants/{restaurant}/menu', [FoodPulseController::class, 'menu'])
    ->whereNumber('restaurant');
Route::post('/cart/checkout', [FoodPulseController::class, 'checkout']);
Route::get('/orders/{orderNumber}/confirmation', [FoodPulseController::class, 'orderConfirmation']);
