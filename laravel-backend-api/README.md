# PulseLocal Laravel API

Laravel API for PulseLocal checkout-risk orchestration.

Flutter calls Laravel at `POST /api/checkout/risk`. Laravel validates the
checkout payload, calls the FastAPI ML service at `/predict`, and returns the
prediction result to Flutter. Flutter must not call the ML service directly.

## Environment

```powershell
copy .env.example .env
composer install
php artisan key:generate
```

For local non-Docker development, keep:

```dotenv
ML_SERVICE_URL=http://127.0.0.1:8001
ML_SERVICE_TIMEOUT_SECONDS=2
```

Docker Compose overrides the ML URL to service networking:

```dotenv
ML_SERVICE_URL=http://ml-service:8001
```

## Run

```powershell
php artisan serve --host=127.0.0.1 --port=8000
```

## API Checks

```powershell
php artisan route:list --path=api
Invoke-RestMethod http://127.0.0.1:8000/api/health
```

Checkout-risk request:

```powershell
$body = @{
  rider_to_order_ratio = 0.45
  merchant_prep_time = 25
  traffic_corridor_intensity = 'high'
  weather_category = 'rainy'
  delivery_distance_km = 4.2
  address_complexity = 'medium'
  payment_method = 'cod'
} | ConvertTo-Json

Invoke-RestMethod -Uri http://127.0.0.1:8000/api/checkout/risk `
  -Method Post `
  -ContentType 'application/json' `
  -Body $body
```

## Test

```powershell
php artisan test
```
