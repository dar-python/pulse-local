<?php

use App\Http\Controllers\Api\Admin\ModelMetadataController;
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

<<<<<<< HEAD
Route::post('/auth/register', [MobileAuthController::class, 'register']);
Route::post('/auth/login', [MobileAuthController::class, 'login']);
Route::put('/auth/profile', [MobileAuthController::class, 'updateProfile']);
Route::put('/auth/password', [MobileAuthController::class, 'updatePassword']);
=======
Route::middleware(['web', 'admin.session'])
    ->prefix('admin')
    ->name('api.admin.')
    ->group(function (): void {
        Route::get('/model-metadata', ModelMetadataController::class)
            ->name('model-metadata');
    });
>>>>>>> 18df08fdba0b440f2f19572b1e7b31a29cc5205f

Route::get('/restaurants', [FoodPulseController::class, 'restaurants']);
Route::get('/restaurants/{restaurant}/menu', [FoodPulseController::class, 'menu'])
    ->whereNumber('restaurant');
Route::post('/cart/checkout', [FoodPulseController::class, 'checkout']);
Route::get('/orders/{orderNumber}/confirmation', [FoodPulseController::class, 'orderConfirmation']);
