<?php

use App\Http\Controllers\CheckoutRiskController;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'laravel-api',
    ]);
});

Route::post('/checkout/risk', CheckoutRiskController::class);
