from typing import Literal

from fastapi import FastAPI
from pydantic import BaseModel, Field


app = FastAPI(title="PulseLocal ML Service", version="0.1.0")


TrafficLevel = Literal["light", "moderate", "heavy"]
WeatherCategory = Literal["clear", "rainy", "stormy"]
PaymentMethod = Literal["cod", "prepaid"]


class CheckoutRiskFeatures(BaseModel):
    rider_to_order_ratio: float = Field(ge=0.0, le=1.0)
    merchant_prep_time: int = Field(ge=0)
    traffic_level: TrafficLevel
    weather_category: WeatherCategory
    delivery_distance_km: float = Field(ge=0.0)
    payment_method: PaymentMethod


class CheckoutRiskPrediction(BaseModel):
    risk_score: float
    risk_level: Literal["Low", "Medium", "High"]
    recommendation: str


RECOMMENDATIONS = {
    "Low": "Low fulfillment risk. Proceed with standard checkout.",
    "Medium": (
        "Moderate fulfillment risk. Show realistic ETA and monitor merchant readiness."
    ),
    "High": "High fulfillment risk. Adjust ETA and notify merchant.",
}


@app.get("/")
def service_status() -> dict[str, str]:
    return {
        "service": "PulseLocal ML Service",
        "status": "running",
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.post("/predict", response_model=CheckoutRiskPrediction)
def predict(features: CheckoutRiskFeatures) -> CheckoutRiskPrediction:
    risk_score = calculate_risk_score(features)
    risk_level = classify_risk_level(risk_score)

    return CheckoutRiskPrediction(
        risk_score=risk_score,
        risk_level=risk_level,
        recommendation=RECOMMENDATIONS[risk_level],
    )


def calculate_risk_score(features: CheckoutRiskFeatures) -> float:
    score = 0.10

    if features.rider_to_order_ratio < 0.50:
        score += 0.25

    if features.merchant_prep_time >= 20:
        score += 0.20

    if features.traffic_level == "heavy":
        score += 0.15

    if features.weather_category == "rainy":
        score += 0.10
    elif features.weather_category == "stormy":
        score += 0.20

    if features.delivery_distance_km >= 5.0:
        score += 0.10

    if features.payment_method == "cod":
        score += 0.05

    return round(max(0.0, min(score, 1.0)), 2)


def classify_risk_level(risk_score: float) -> Literal["Low", "Medium", "High"]:
    if risk_score <= 0.39:
        return "Low"

    if risk_score <= 0.69:
        return "Medium"

    return "High"
