<?php

use App\Http\Controllers\CheckoutRiskController;
use Illuminate\Support\Facades\Route;

Route::post('/checkout/risk', CheckoutRiskController::class);
