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
    "Distance_km": 5.0,
    "Weather": "rainy",
    "Traffic_Level": "medium",
    "Time_of_Day": "evening",
    "Vehicle_Type": "motorcycle",
    "Preparation_Time_min": 25,
    "Courier_Experience_yrs": 2.0
  }'
```

## Endpoints

- `GET /` returns service status.
- `GET /health` returns health status.
- `POST /predict` returns the trained model fulfillment risk prediction.
