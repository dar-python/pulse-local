# PulseLocal ML Service

FastAPI service for the PulseLocal Sprint 1 checkout fulfillment risk bridge.
Laravel calls this service to get a risk score, risk level, and recommendation
for checkout inputs. Flutter must not call this service directly.

This service uses deterministic mock prediction logic for Sprint 1 only. It does
not train or load a real Logistic Regression model yet.

## Local Setup

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Run

```powershell
uvicorn app:app --reload --host 127.0.0.1 --port 8001
```

## Test

```powershell
pytest
```

## Sample Request

```powershell
curl -X POST "http://127.0.0.1:8001/predict" `
  -H "Content-Type: application/json" `
  -d '{
    "rider_to_order_ratio": 0.45,
    "merchant_prep_time": 25,
    "traffic_level": "heavy",
    "weather_category": "rainy",
    "delivery_distance_km": 4.2,
    "payment_method": "cod"
  }'
```

## Endpoints

- `GET /` returns service status.
- `GET /health` returns health status.
- `POST /predict` returns the Sprint 1 mock fulfillment risk prediction.
