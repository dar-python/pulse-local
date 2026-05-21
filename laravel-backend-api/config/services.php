<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ml' => [
        'url' => env('ML_SERVICE_URL', 'http://127.0.0.1:8001'),
        'timeout' => (int) env('ML_SERVICE_TIMEOUT_SECONDS', 2),
    ],

    'ml_service' => [
        'url' => env('ML_SERVICE_URL', 'http://127.0.0.1:8001'),
        'timeout' => (int) env('ML_SERVICE_TIMEOUT_SECONDS', 2),
    ],

    'weatherapi' => [
        'base_url' => env('WEATHERAPI_BASE_URL', 'https://api.weatherapi.com/v1'),
        'key' => env('WEATHERAPI_KEY'),
        'timeout_seconds' => (int) env('WEATHERAPI_TIMEOUT_SECONDS', 2),
        'cache_ttl_seconds' => (int) env('WEATHERAPI_CACHE_TTL_SECONDS', 600),
        'default_latitude' => (float) env('DEFAULT_WEATHER_LATITUDE', 14.5995),
        'default_longitude' => (float) env('DEFAULT_WEATHER_LONGITUDE', 120.9842),
    ],

    'checkout_risk' => [
        'fallback_score' => (float) env('CHECKOUT_RISK_FALLBACK_SCORE', 0.50),
        'fallback_level' => env('CHECKOUT_RISK_FALLBACK_LEVEL', 'Unknown'),
        'fallback_source' => env('CHECKOUT_RISK_FALLBACK_SOURCE', 'laravel-fallback'),
        'fallback_recommendation' => env(
            'CHECKOUT_RISK_FALLBACK_RECOMMENDATION',
            'Prediction service unavailable. Proceed with standard checkout risk.'
        ),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

];
