from app import app
from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel, Field


app = FastAPI(
    title="PulseLocal ML Service",
    version="1.0.0",
)


WeatherCategory = Literal["clear", "rainy", "stormy"]
TrafficIntensity = Literal["low", "medium", "high"]
AddressComplexity = Literal["low", "medium", "high"]
PaymentMethod = Literal["cod", "prepaid"]


class PredictionRequest(BaseModel):
    rider_to_order_ratio: float = Field(ge=0.0, description="Available riders divided by active orders")
    merchant_prep_time: int = Field(ge=0, description="Merchant preparation time in minutes")
    traffic_corridor_intensity: TrafficIntensity
    delivery_distance_km: float = Field(ge=0.0)
    address_complexity: AddressComplexity
    weather_category: WeatherCategory
    payment_method: PaymentMethod


class PredictionResponse(BaseModel):
    risk_score: float
    risk_level: Literal["Low", "Medium", "High"]
    recommendation: str
    source: Literal["ml-service"]


@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "ml-service",
    }


@app.post("/predict", response_model=PredictionResponse)
def predict_fulfillment_risk(payload: PredictionRequest):
    risk_score = calculate_mock_risk_score(payload)
    risk_level = classify_risk_level(risk_score)

    return PredictionResponse(
        risk_score=risk_score,
        risk_level=risk_level,
        recommendation=build_recommendation(risk_level),
        source="ml-service",
    )


def calculate_mock_risk_score(payload: PredictionRequest) -> float:
    score = 0.10

    # Low rider availability increases fulfillment risk.
    rider_pressure = max(0.0, 1.0 - min(payload.rider_to_order_ratio, 1.0))
    score += rider_pressure * 0.25

    # Longer merchant prep time increases risk.
    score += min(payload.merchant_prep_time / 90, 1.0) * 0.25

    # Traffic intensity.
    traffic_weights = {
        "low": 0.02,
        "medium": 0.10,
        "high": 0.18,
    }
    score += traffic_weights[payload.traffic_corridor_intensity]

    # Distance pressure.
    score += min(payload.delivery_distance_km / 10, 1.0) * 0.12

    # Address complexity.
    address_weights = {
        "low": 0.01,
        "medium": 0.06,
        "high": 0.12,
    }
    score += address_weights[payload.address_complexity]

    # Weather risk.
    weather_weights = {
        "clear": 0.00,
        "rainy": 0.08,
        "stormy": 0.16,
    }
    score += weather_weights[payload.weather_category]

    # COD can increase operational risk due to failed handoff/payment friction.
    if payload.payment_method == "cod":
        score += 0.04

    return round(min(max(score, 0.0), 1.0), 2)


def classify_risk_level(risk_score: float) -> Literal["Low", "Medium", "High"]:
    if risk_score < 0.40:
        return "Low"

    if risk_score < 0.70:
        return "Medium"

    return "High"


def build_recommendation(risk_level: str) -> str:
    if risk_level == "Low":
        return "Low fulfillment risk. Proceed with normal checkout."

    if risk_level == "Medium":
        return "Medium fulfillment risk. Show advisory and realistic ETA."

    return "High fulfillment risk. Adjust ETA and notify merchant."