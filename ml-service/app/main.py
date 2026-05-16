import json
from functools import lru_cache
from pathlib import Path
from typing import Any, Literal

import joblib
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel, Field


app = FastAPI(
    title="PulseLocal ML Service",
    version="1.0.0",
)


MODEL_DIR = Path(__file__).resolve().parent / "models"
MODEL_PATH = MODEL_DIR / "pulselocal_logistic_regression_model.joblib"
METADATA_PATH = MODEL_DIR / "pulselocal_model_metadata.json"

MODEL_FEATURE_COLUMNS = [
    "Distance_km",
    "Weather",
    "Traffic_Level",
    "Time_of_Day",
    "Vehicle_Type",
    "Preparation_Time_min",
    "Courier_Experience_yrs",
]

RECOMMENDATIONS = {
    "Low": "Low fulfillment risk. Proceed with normal checkout.",
    "Medium": "Medium fulfillment risk. Show advisory and realistic ETA.",
    "High": "High fulfillment risk. Adjust ETA and notify merchant.",
}


WeatherCategory = Literal["clear", "rainy", "stormy"]
TrafficIntensity = Literal["low", "medium", "high"]
AddressComplexity = Literal["low", "medium", "high"]
PaymentMethod = Literal["cod", "cash", "gcash", "card"]
RiskLevel = Literal["Low", "Medium", "High"]


class PredictionRequest(BaseModel):
    rider_to_order_ratio: float = Field(
        ge=0.0,
        description="Available riders divided by active orders",
    )
    merchant_prep_time: int = Field(
        ge=0,
        description="Merchant preparation time in minutes",
    )
    traffic_corridor_intensity: TrafficIntensity
    weather_category: WeatherCategory
    delivery_distance_km: float = Field(ge=0.0)
    address_complexity: AddressComplexity
    payment_method: PaymentMethod


class PredictionResponse(BaseModel):
    risk_score: float
    risk_level: RiskLevel
    recommendation: str
    source: Literal["ml-service"]


@app.get("/")
def service_status() -> dict[str, str]:
    return {
        "service": "PulseLocal ML Service",
        "status": "running",
    }


@app.get("/health")
def health_check() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "ml-service",
    }


@app.post("/predict", response_model=PredictionResponse)
def predict_fulfillment_risk(payload: PredictionRequest) -> PredictionResponse:
    input_df = adapt_public_request_to_model_input(payload)
    risk_score = round(float(load_model().predict_proba(input_df)[0][1]), 2)
    risk_level = classify_risk_level(risk_score)

    return PredictionResponse(
        risk_score=risk_score,
        risk_level=risk_level,
        recommendation=RECOMMENDATIONS[risk_level],
        source="ml-service",
    )


@lru_cache
def load_model() -> Any:
    return joblib.load(MODEL_PATH)


@lru_cache
def load_metadata() -> dict[str, Any]:
    with METADATA_PATH.open("r", encoding="utf-8") as metadata_file:
        return json.load(metadata_file)


def adapt_public_request_to_model_input(payload: PredictionRequest) -> pd.DataFrame:
    model_row = {
        "Distance_km": payload.delivery_distance_km,
        "Weather": payload.weather_category,
        "Traffic_Level": payload.traffic_corridor_intensity,
        # Sprint 1 MVP temporary default until the app collects this field or the
        # model is retrained with app-aligned features.
        "Time_of_Day": "evening",
        # Sprint 1 MVP temporary default until the app collects this field or the
        # model is retrained with app-aligned features.
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": payload.merchant_prep_time,
        # Sprint 1 MVP temporary default until the app collects this field or the
        # model is retrained with app-aligned features.
        "Courier_Experience_yrs": 1.0,
    }

    return pd.DataFrame([model_row], columns=MODEL_FEATURE_COLUMNS)


def classify_risk_level(risk_score: float) -> RiskLevel:
    thresholds = load_metadata()["risk_thresholds"]

    if thresholds["low"]["min"] <= risk_score <= thresholds["low"]["max"]:
        return "Low"

    if thresholds["medium"]["min"] <= risk_score <= thresholds["medium"]["max"]:
        return "Medium"

    if thresholds["high"]["min"] <= risk_score <= thresholds["high"]["max"]:
        return "High"

    if risk_score < thresholds["low"]["min"]:
        return "Low"

    return "High"
