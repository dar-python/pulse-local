# PulseLocal Sprint 1 API Contract

## Architecture Flow

Flutter Mobile App → Laravel Backend API → Python ML Service → Laravel Backend API → Flutter UI

Flutter must never call the ML service directly. Laravel is the orchestrator.

---

## 1. Flutter → Laravel

### Endpoint

POST /api/checkout/risk

### Purpose

Receives checkout features from the mobile app and returns a fulfillment risk prediction.

### Request Body

```json
{
  "rider_to_order_ratio": 0.45,
  "merchant_prep_time": 25,
  "traffic_corridor_intensity": "high",
  "weather_category": "rainy",
  "delivery_distance_km": 4.2,
  "address_complexity": "medium",
  "payment_method": "cod"
}
```

Accepted enum values:

- `traffic_corridor_intensity`: `low`, `medium`, `high`
- `weather_category`: `clear`, `rainy`, `stormy`
- `address_complexity`: `low`, `medium`, `high`
- `payment_method`: `cod`, `cash`, `gcash`, `card`

### Laravel Response Body

```json
{
  "success": true,
  "source": "ml-service",
  "data": {
    "risk_score": 0.72,
    "risk_level": "High",
    "recommendation": "High fulfillment risk. Adjust ETA and notify merchant."
  }
}
```

When the Python ML service is unavailable, Laravel still returns `200 OK` with
the same wrapper and a fallback payload:

```json
{
  "success": true,
  "source": "laravel-fallback",
  "data": {
    "risk_score": 0.5,
    "risk_level": "Unknown",
    "recommendation": "Prediction service unavailable. Proceed with standard checkout risk."
  }
}
```
