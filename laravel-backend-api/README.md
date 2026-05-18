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
  restaurant_id = 1
  restaurant_slug = 'tambayan-grill'
  items = @(
    @{
      id = 1
      name = 'Pork Sinigang'
      category = 'Bestsellers'
      quantity = 1
      unit_price = 185
    }
  )
  delivery_address = @{
    label = 'Marasbaras, Tacloban City'
    notes = 'Zone 7, Leyte, Philippines'
  }
  payment_method = 'cod'
  subtotal = 185
  total_quantity = 1
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Uri http://127.0.0.1:8000/api/checkout/risk `
  -Method Post `
  -ContentType 'application/json' `
  -Body $body
```

## Test

```powershell
php artisan test
```
