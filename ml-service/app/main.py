import json
from json import JSONDecodeError
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from functools import lru_cache
from pathlib import Path
from typing import Any, Literal

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict, Field, ValidationError

from app.config import settings


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    load_model()
    load_metadata()
    yield


app = FastAPI(
    title="PulseLocal ML Service",
    version="1.0.0",
    lifespan=lifespan,
)


SERVICE_DIR = Path(__file__).resolve().parents[1]
MODEL_DIR = Path(__file__).resolve().parent / "models"
CONFIGURED_MODEL_PATH = Path(settings.model_path)
MODEL_PATH = (
    CONFIGURED_MODEL_PATH
    if CONFIGURED_MODEL_PATH.is_absolute()
    else SERVICE_DIR / CONFIGURED_MODEL_PATH
)
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
TimeOfDay = Literal["morning", "afternoon", "evening", "night"]
VehicleType = Literal["bicycle", "motorcycle"]
RiskLevel = Literal["Low", "Medium", "High"]


class PredictionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    Distance_km: float = Field(ge=0.0)
    Weather: WeatherCategory
    Traffic_Level: TrafficIntensity
    Time_of_Day: TimeOfDay
    Vehicle_Type: VehicleType
    Preparation_Time_min: int = Field(ge=0)
    Courier_Experience_yrs: float = Field(ge=0.0)


class PredictionResponse(BaseModel):
    risk_score: float
    risk_level: RiskLevel
    recommendation: str
    source: Literal["ml-service"]


class RiskThreshold(BaseModel):
    min: float
    max: float


class RiskThresholds(BaseModel):
    low: RiskThreshold
    medium: RiskThreshold
    high: RiskThreshold


class TestMetrics(BaseModel):
    accuracy: float
    precision: float
    recall: float
    f1_score: float
    roc_auc: float


class CrossValidation(BaseModel):
    method: str
    n_splits: int
    mean_roc_auc: float
    std_roc_auc: float
    scores: list[float]


class ModelMetadataResponse(BaseModel):
    model_name: str
    model_type: str
    target_column: str
    features: list[str]
    numeric_features: list[str]
    categorical_features: list[str]
    risk_thresholds: RiskThresholds
    test_metrics: TestMetrics
    cross_validation: CrossValidation


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


@app.get("/metadata", response_model=ModelMetadataResponse)
def model_metadata() -> ModelMetadataResponse:
    try:
        return ModelMetadataResponse.model_validate(load_metadata())
    except FileNotFoundError as exc:
        raise HTTPException(
            status_code=503,
            detail={
                "error": "model_metadata_unavailable",
                "message": "Trained model metadata file is missing.",
            },
        ) from exc
    except (JSONDecodeError, TypeError, ValidationError) as exc:
        raise HTTPException(
            status_code=503,
            detail={
                "error": "model_metadata_invalid",
                "message": "Trained model metadata file is invalid.",
            },
        ) from exc


@app.post("/predict", response_model=PredictionResponse)
def predict_fulfillment_risk(payload: PredictionRequest) -> PredictionResponse:
    input_df = model_input_frame(payload)
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


def model_input_frame(payload: PredictionRequest) -> pd.DataFrame:
    model_row = {
        "Distance_km": payload.Distance_km,
        "Weather": {
            "clear": "Clear",
            "rainy": "Rainy",
            "stormy": "Rainy",
        }[payload.Weather],
        "Traffic_Level": {
            "low": "Low",
            "medium": "Medium",
            "high": "High",
        }[payload.Traffic_Level],
        "Time_of_Day": {
            "morning": "Morning",
            "afternoon": "Afternoon",
            "evening": "Evening",
            "night": "Night",
        }[payload.Time_of_Day],
        "Vehicle_Type": {
            "bicycle": "Bike",
            "motorcycle": "Scooter",
        }[payload.Vehicle_Type],
        "Preparation_Time_min": payload.Preparation_Time_min,
        "Courier_Experience_yrs": payload.Courier_Experience_yrs,
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
