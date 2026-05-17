# PulseLocal ML Service

FastAPI service for the PulseLocal Sprint 1 checkout fulfillment risk bridge.
Laravel calls this service to get a risk score, risk level, and recommendation
for checkout inputs. Flutter must not call this service directly.

This service loads the trained PulseLocal Logistic Regression sklearn Pipeline
from `app/models/pulselocal_logistic_regression_model.joblib`.

If `MODEL_PATH` is set for local scripts or Docker, point it at:

```dotenv
MODEL_PATH=./app/models/pulselocal_logistic_regression_model.joblib
```

## Local Setup

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Run

```powershell
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001
```

The Dockerfile also starts `app.main:app` explicitly so the container serves the
current FastAPI app module.

## Test

```powershell
python -m pytest
```

## Sample Request

```powershell
curl -X POST "http://127.0.0.1:8001/predict" `
  -H "Content-Type: application/json" `
  -d '{
    "rider_to_order_ratio": 0.45,
    "merchant_prep_time": 25,
    "traffic_corridor_intensity": "high",
    "weather_category": "rainy",
    "delivery_distance_km": 4.2,
    "address_complexity": "medium",
    "payment_method": "cod"
  }'
```

## Endpoints

- `GET /` returns service status.
- `GET /health` returns health status.
- `POST /predict` returns the trained model fulfillment risk prediction.
