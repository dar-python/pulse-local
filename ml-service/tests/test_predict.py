from collections import Counter

from fastapi.testclient import TestClient
from sklearn.calibration import CalibratedClassifierCV
from sklearn.pipeline import Pipeline

import app.main as ml_app
from app.config import Settings


client = TestClient(ml_app.app)


VALID_MODEL_PAYLOAD = {
    "Distance_km": 4.2,
    "Weather": "rainy",
    "Traffic_Level": "medium",
    "Time_of_Day": "evening",
    "Vehicle_Type": "motorcycle",
    "Preparation_Time_min": 25,
    "Courier_Experience_yrs": 2.0,
}


DEMO_SCENARIOS = [
    {
        "Distance_km": 2.8,
        "Weather": "clear",
        "Traffic_Level": "low",
        "Time_of_Day": "afternoon",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 15,
        "Courier_Experience_yrs": 3.5,
    },
    {
        "Distance_km": 5.0,
        "Weather": "rainy",
        "Traffic_Level": "medium",
        "Time_of_Day": "evening",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 25,
        "Courier_Experience_yrs": 2.0,
    },
    {
        "Distance_km": 6.6,
        "Weather": "stormy",
        "Traffic_Level": "high",
        "Time_of_Day": "night",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 35,
        "Courier_Experience_yrs": 1.0,
    },
    {
        "Distance_km": 1.2,
        "Weather": "clear",
        "Traffic_Level": "low",
        "Time_of_Day": "morning",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 8,
        "Courier_Experience_yrs": 4.5,
    },
    {
        "Distance_km": 1.8,
        "Weather": "clear",
        "Traffic_Level": "low",
        "Time_of_Day": "afternoon",
        "Vehicle_Type": "bicycle",
        "Preparation_Time_min": 10,
        "Courier_Experience_yrs": 3.0,
    },
    {
        "Distance_km": 3.6,
        "Weather": "rainy",
        "Traffic_Level": "medium",
        "Time_of_Day": "afternoon",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 18,
        "Courier_Experience_yrs": 2.0,
    },
    {
        "Distance_km": 4.0,
        "Weather": "clear",
        "Traffic_Level": "medium",
        "Time_of_Day": "evening",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 22,
        "Courier_Experience_yrs": 2.5,
    },
    {
        "Distance_km": 7.8,
        "Weather": "stormy",
        "Traffic_Level": "high",
        "Time_of_Day": "night",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 38,
        "Courier_Experience_yrs": 0.8,
    },
    {
        "Distance_km": 6.8,
        "Weather": "stormy",
        "Traffic_Level": "high",
        "Time_of_Day": "evening",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 40,
        "Courier_Experience_yrs": 1.2,
    },
    {
        "Distance_km": 2.0,
        "Weather": "clear",
        "Traffic_Level": "low",
        "Time_of_Day": "morning",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 12,
        "Courier_Experience_yrs": 5.0,
    },
    {
        "Distance_km": 3.2,
        "Weather": "clear",
        "Traffic_Level": "medium",
        "Time_of_Day": "evening",
        "Vehicle_Type": "bicycle",
        "Preparation_Time_min": 20,
        "Courier_Experience_yrs": 1.5,
    },
    {
        "Distance_km": 2.6,
        "Weather": "rainy",
        "Traffic_Level": "medium",
        "Time_of_Day": "morning",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 20,
        "Courier_Experience_yrs": 2.0,
    },
    {
        "Distance_km": 8.5,
        "Weather": "clear",
        "Traffic_Level": "high",
        "Time_of_Day": "night",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 30,
        "Courier_Experience_yrs": 1.0,
    },
    {
        "Distance_km": 5.5,
        "Weather": "clear",
        "Traffic_Level": "medium",
        "Time_of_Day": "afternoon",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 24,
        "Courier_Experience_yrs": 4.0,
    },
    {
        "Distance_km": 1.5,
        "Weather": "rainy",
        "Traffic_Level": "low",
        "Time_of_Day": "morning",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 10,
        "Courier_Experience_yrs": 5.0,
    },
    {
        "Distance_km": 7.0,
        "Weather": "stormy",
        "Traffic_Level": "high",
        "Time_of_Day": "night",
        "Vehicle_Type": "bicycle",
        "Preparation_Time_min": 32,
        "Courier_Experience_yrs": 0.5,
    },
    {
        "Distance_km": 4.4,
        "Weather": "clear",
        "Traffic_Level": "medium",
        "Time_of_Day": "afternoon",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 24,
        "Courier_Experience_yrs": 2.0,
    },
    {
        "Distance_km": 10.0,
        "Weather": "stormy",
        "Traffic_Level": "high",
        "Time_of_Day": "evening",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 45,
        "Courier_Experience_yrs": 0.5,
    },
]


def test_root_endpoint_returns_service_status():
    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "service": "PulseLocal ML Service",
        "status": "running",
    }


def test_health_endpoint_returns_healthy_status():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "service": "ml-service",
    }


def test_app_startup_warms_model_and_metadata(monkeypatch):
    calls = []

    monkeypatch.setattr(ml_app, "load_model", lambda: calls.append("model"))
    monkeypatch.setattr(ml_app, "load_metadata", lambda: calls.append("metadata"))

    with TestClient(ml_app.app):
        pass

    assert calls == ["model", "metadata"]


def test_loaded_model_is_trained_joblib_pipeline():
    ml_app.load_model.cache_clear()

    model = ml_app.load_model()

    assert isinstance(model, Pipeline)
    assert "preprocessor" in model.named_steps
    assert hasattr(model, "predict_proba")


def test_loaded_model_uses_calibrated_logistic_regression():
    ml_app.load_model.cache_clear()
    ml_app.load_metadata.cache_clear()

    model = ml_app.load_model()
    metadata = ml_app.load_metadata()

    assert metadata["calibration"]["enabled"] is True
    assert metadata["calibration"]["method"] == "sigmoid"
    assert isinstance(model.named_steps["classifier"], CalibratedClassifierCV)


def test_predict_uses_exact_trained_model_feature_schema(monkeypatch):
    class FakePipeline:
        def __init__(self):
            self.input_df = None

        def predict_proba(self, input_df):
            self.input_df = input_df.copy()
            return [[0.28, 0.72]]

    fake_pipeline = FakePipeline()
    monkeypatch.setattr(ml_app, "load_model", lambda: fake_pipeline)

    response = client.post("/predict", json=VALID_MODEL_PAYLOAD)

    assert response.status_code == 200
    assert response.json() == {
        "risk_score": 0.72,
        "risk_level": "High",
        "recommendation": "High fulfillment risk. Adjust ETA and notify merchant.",
        "source": "ml-service",
    }
    assert list(fake_pipeline.input_df.columns) == [
        "Distance_km",
        "Weather",
        "Traffic_Level",
        "Time_of_Day",
        "Vehicle_Type",
        "Preparation_Time_min",
        "Courier_Experience_yrs",
    ]
    assert fake_pipeline.input_df.iloc[0].to_dict() == {
        "Distance_km": 4.2,
        "Weather": "Rainy",
        "Traffic_Level": "Medium",
        "Time_of_Day": "Evening",
        "Vehicle_Type": "Scooter",
        "Preparation_Time_min": 25,
        "Courier_Experience_yrs": 2.0,
    }


def test_predict_returns_200_with_valid_model_input():
    response = client.post("/predict", json=VALID_MODEL_PAYLOAD)

    assert response.status_code == 200


def test_predict_returns_risk_score_between_zero_and_one():
    response = client.post("/predict", json=VALID_MODEL_PAYLOAD)

    assert response.status_code == 200
    assert 0 <= response.json()["risk_score"] <= 1


def test_predict_returns_supported_risk_level():
    response = client.post("/predict", json=VALID_MODEL_PAYLOAD)

    assert response.status_code == 200
    assert response.json()["risk_level"] in {"Low", "Medium", "High"}


def test_predict_response_contract_remains_unchanged_with_real_model():
    response = client.post("/predict", json=VALID_MODEL_PAYLOAD)

    assert response.status_code == 200
    assert set(response.json().keys()) == {
        "risk_score",
        "risk_level",
        "recommendation",
        "source",
    }


def test_different_feature_rows_return_different_risk_scores():
    low_risk_response = client.post(
        "/predict",
        json={
            "Distance_km": 2.8,
            "Weather": "clear",
            "Traffic_Level": "low",
            "Time_of_Day": "afternoon",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 15,
            "Courier_Experience_yrs": 3.5,
        },
    )
    high_risk_response = client.post(
        "/predict",
        json={
            "Distance_km": 6.6,
            "Weather": "stormy",
            "Traffic_Level": "high",
            "Time_of_Day": "night",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 35,
            "Courier_Experience_yrs": 1.0,
        },
    )

    assert low_risk_response.status_code == 200
    assert high_risk_response.status_code == 200
    assert (
        low_risk_response.json()["risk_score"]
        != high_risk_response.json()["risk_score"]
    )


def test_demo_scenarios_are_distinguishable_and_not_collapsed_to_extremes():
    responses = [client.post("/predict", json=scenario) for scenario in DEMO_SCENARIOS]
    payloads = [response.json() for response in responses]
    scores = [payload["risk_score"] for payload in payloads]
    levels = Counter(payload["risk_level"] for payload in payloads)

    assert all(response.status_code == 200 for response in responses)
    assert min(scores) < 0.15
    assert max(scores) > 0.85
    assert len(set(scores)) >= 6
    assert len(levels) >= 3
    assert sum(score <= 0.01 for score in scores) <= 3
    assert sum(score >= 0.99 for score in scores) <= 3


def test_mock_prediction_is_disabled_by_default(monkeypatch):
    monkeypatch.delenv("MOCK_PREDICTION_ENABLED", raising=False)

    assert Settings().mock_prediction_enabled is False


def test_mock_mode_does_not_override_trained_model_unless_enabled(monkeypatch):
    class FakePipeline:
        def predict_proba(self, input_df):
            return [[0.97, 0.03]]

    monkeypatch.setattr(ml_app, "load_model", lambda: FakePipeline())

    response = client.post("/predict", json=VALID_MODEL_PAYLOAD)

    assert response.status_code == 200
    assert response.json()["risk_score"] == 0.03


def test_risk_level_uses_metadata_threshold_boundaries():
    assert ml_app.classify_risk_level(0.39) == "Low"
    assert ml_app.classify_risk_level(0.40) == "Medium"
    assert ml_app.classify_risk_level(0.69) == "Medium"
    assert ml_app.classify_risk_level(0.70) == "High"


def test_validation_error_for_invalid_model_feature_value():
    invalid_payload = {
        **VALID_MODEL_PAYLOAD,
        "Traffic_Level": "jammed",
    }

    response = client.post("/predict", json=invalid_payload)

    assert response.status_code == 422
    assert any(
        error["loc"][-1] == "Traffic_Level" for error in response.json()["detail"]
    )


def test_validation_error_for_legacy_public_payload_shape():
    response = client.post(
        "/predict",
        json={
            "rider_to_order_ratio": 0.45,
            "merchant_prep_time": 25,
            "traffic_corridor_intensity": "high",
            "weather_category": "rainy",
            "delivery_distance_km": 4.2,
            "address_complexity": "medium",
            "payment_method": "cod",
        },
    )

    assert response.status_code == 422
    assert any(
        error["loc"][-1] == "Distance_km" for error in response.json()["detail"]
    )
