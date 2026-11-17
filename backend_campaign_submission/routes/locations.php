<?php

// Include from routes/api.php. Both spellings support older installed clients.
\Illuminate\Support\Facades\Route::prefix('v1')
    ->middleware(['cors', 'auth:sanctum', 'throttle:30,1'])->group(function () {
        $controller = \App\Http\Controllers\Api\CampaignLocationController::class;
        \Illuminate\Support\Facades\Route::get('/locations/search', [$controller, 'search']);
        \Illuminate\Support\Facades\Route::get('/locations/reverse', [$controller, 'reverse']);
        \Illuminate\Support\Facades\Route::get('/locations/revese', [$controller, 'reverse']);
    });
