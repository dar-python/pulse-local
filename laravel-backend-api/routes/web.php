<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    // Values are verified against ml-service/app/models/pulselocal_model_metadata.json.
    $landingMetrics = [
        ['label' => 'Accuracy', 'value' => '92.0%', 'bar' => 92],
        ['label' => 'Precision', 'value' => '93.33%', 'bar' => 93.33],
        ['label' => 'Recall', 'value' => '94.74%', 'bar' => 94.74],
        ['label' => 'F1-Score', 'value' => '94.03%', 'bar' => 94.03],
        ['label' => 'ROC-AUC', 'value' => '0.9777', 'bar' => 97.77],
    ];

    $landingCrossValidation = [
        ['label' => 'Cross-validation mean ROC-AUC', 'value' => '0.9669'],
        ['label' => 'Cross-validation std ROC-AUC', 'value' => '0.0053'],
    ];

    return view('landing.index', [
        'landingMetrics' => $landingMetrics,
        'landingCrossValidation' => $landingCrossValidation,
    ]);
});

// @Dashboard: Session-based Blade admin routes, isolated from the JSON API.
Route::prefix('admin')->name('admin.')->group(function (): void {
    Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AuthController::class, 'login'])->name('login.store');
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
    Route::get('/dashboard', DashboardController::class)
        ->middleware('admin.session')
        ->name('dashboard');
});
