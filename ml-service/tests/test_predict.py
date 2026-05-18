from fastapi.testclient import TestClient
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
