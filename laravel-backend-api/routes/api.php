<?php

use App\Http\Controllers\Api\Admin\ModelMetadataController;
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

Route::middleware(['web', 'admin.session'])
    ->prefix('admin')
    ->name('api.admin.')
    ->group(function (): void {
        Route::get('/model-metadata', ModelMetadataController::class)
            ->name('model-metadata');
    });

Route::get('/restaurants', [FoodPulseController::class, 'restaurants']);
Route::get('/restaurants/{restaurant}/menu', [FoodPulseController::class, 'menu'])
    ->whereNumber('restaurant');
Route::post('/cart/checkout', [FoodPulseController::class, 'checkout']);
Route::get('/orders/{orderNumber}/confirmation', [FoodPulseController::class, 'orderConfirmation']);
