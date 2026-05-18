# PulseLocal / FoodPulse

PulseLocal is a final-project quick-commerce prototype for checkout-level
fulfillment-risk prediction. The architecture is intentionally split into:

- Flutter mobile app: `flutter-mobile-app`
- Laravel backend/API: `laravel-backend-api`
- FastAPI Logistic Regression service: `ml-service`
- Training pipeline and dataset checks: `ml-training`

Flutter sends checkout data to Laravel only. Laravel calls the Python ML service
internally and returns the risk result to Flutter.

## Local URLs

- Flutter Laravel base URL on Android emulator: `http://10.0.2.2:8000`
- Flutter Laravel base URL on Windows desktop: `http://127.0.0.1:8000`
- Docker Laravel API through nginx: `http://localhost:8080`
- Docker ML service for local testing: `http://localhost:8001`

## Run With Docker

```powershell
copy laravel-backend-api\.env.example laravel-backend-api\.env
copy flutter-mobile-app\.env.example flutter-mobile-app\.env
copy ml-service\.env.example ml-service\.env
docker compose build
docker compose up -d
```

Health checks:

```powershell
Invoke-RestMethod http://localhost:8080/api/health
Invoke-RestMethod http://localhost:8001/health
```

Checkout-risk request through Laravel:

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

Invoke-RestMethod -Uri http://localhost:8080/api/checkout/risk `
  -Method Post `
  -ContentType 'application/json' `
  -Body $body
```

## Run Components Locally

Flutter:

```powershell
cd flutter-mobile-app
copy .env.example .env
flutter pub get
flutter run --dart-define=LARAVEL_BASE_URL=http://127.0.0.1:8000
```

Laravel:

```powershell
cd laravel-backend-api
copy .env.example .env
composer install
php artisan key:generate
php artisan serve --host=127.0.0.1 --port=8000
```

FastAPI ML service:

```powershell
cd ml-service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001
```

## Verification Commands

Flutter:

```powershell
cd flutter-mobile-app
flutter analyze
flutter test
```

Laravel:

```powershell
cd laravel-backend-api
php artisan route:list --path=api
php artisan test
```

ML service:

```powershell
cd ml-service
python -m pytest
```

Training pipeline:

```powershell
cd ml-training
python -m pytest
```
