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
  "traffic_level": "heavy",
  "weather_category": "rainy",
  "delivery_distance_km": 4.2,
  "payment_method": "cod"
}