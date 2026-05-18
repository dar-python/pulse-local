# PulseLocal Sprint 1 API Contract

## Architecture Flow

Flutter Mobile App → Laravel Backend API → Python ML Service → Laravel Backend API → Flutter UI

Flutter must never call the ML service directly. Laravel is the orchestrator.

---

## 1. Flutter → Laravel

### Endpoint

POST /api/checkout/risk

### Purpose

Receives the current checkout context from the mobile app and returns a
fulfillment risk prediction. Flutter sends context only; Laravel builds the
trained model feature row.

### Request Body

```json
{
  "restaurant_id": 1,
  "restaurant_slug": "tambayan-grill",
  "items": [
    {
      "id": 1,
      "name": "Pork Sinigang",
      "category": "Bestsellers",
      "quantity": 1,
      "unit_price": 185
    }
  ],
  "delivery_address": {
    "label": "Marasbaras, Tacloban City",
    "notes": "Zone 7, Leyte, Philippines"
  },
  "payment_method": "cod",
  "subtotal": 185,
  "total_quantity": 1
}
```

Accepted enum values:

- `payment_method`: `cod`, `cash`, `gcash`, `card`

### Laravel Response Body

```json
{
  "success": true,
  "source": "ml-service",
  "data": {
    "risk_score": 0.72,
    "risk_level": "High",
    "recommendation": "High fulfillment risk. Adjust ETA and notify merchant.",
    "eta_range": "40-55 min"
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
    "recommendation": "Prediction service unavailable. Proceed with standard checkout risk.",
    "eta_range": "30-45 min"
  }
}
```

## 2. Laravel -> Python ML Service

### Endpoint

POST /predict

### Request Body

Laravel sends the trained model feature schema:

```json
{
  "Distance_km": 5.0,
  "Weather": "rainy",
  "Traffic_Level": "medium",
  "Time_of_Day": "evening",
  "Vehicle_Type": "motorcycle",
  "Preparation_Time_min": 25,
  "Courier_Experience_yrs": 2.0
}
```

Accepted enum values:

- `Weather`: `clear`, `rainy`, `stormy`
- `Traffic_Level`: `low`, `medium`, `high`
- `Time_of_Day`: `morning`, `afternoon`, `evening`, `night`
- `Vehicle_Type`: `bicycle`, `motorcycle`
