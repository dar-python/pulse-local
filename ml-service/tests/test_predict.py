from fastapi.testclient import TestClient

from app import main as ml_app


client = TestClient(ml_app.app)


VALID_PUBLIC_PAYLOAD = {
    "rider_to_order_ratio": 0.45,
    "merchant_prep_time": 25,
    "traffic_corridor_intensity": "high",
    "weather_category": "rainy",
    "delivery_distance_km": 4.2,
    "address_complexity": "medium",
    "payment_method": "cod",
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


def test_predict_uses_model_pipeline_with_public_contract_adapter(monkeypatch):
    class FakePipeline:
        def __init__(self):
            self.input_df = None

        def predict_proba(self, input_df):
            self.input_df = input_df.copy()
            return [[0.28, 0.72]]

    fake_pipeline = FakePipeline()
    monkeypatch.setattr(ml_app, "load_model", lambda: fake_pipeline)

    response = client.post("/predict", json=VALID_PUBLIC_PAYLOAD)

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
        "Weather": "rainy",
        "Traffic_Level": "high",
        "Time_of_Day": "evening",
        "Vehicle_Type": "motorcycle",
        "Preparation_Time_min": 25,
        "Courier_Experience_yrs": 1.0,
    }


def test_predict_returns_200_with_valid_public_input():
    response = client.post("/predict", json=VALID_PUBLIC_PAYLOAD)

    assert response.status_code == 200


def test_predict_returns_risk_score_between_zero_and_one():
    response = client.post("/predict", json=VALID_PUBLIC_PAYLOAD)

    assert response.status_code == 200
    assert 0 <= response.json()["risk_score"] <= 1


def test_predict_returns_supported_risk_level():
    response = client.post("/predict", json=VALID_PUBLIC_PAYLOAD)

    assert response.status_code == 200
    assert response.json()["risk_level"] in {"Low", "Medium", "High"}


def test_predict_does_not_require_model_only_fields():
    response = client.post("/predict", json=VALID_PUBLIC_PAYLOAD)

    assert response.status_code == 200
    assert "Time_of_Day" not in VALID_PUBLIC_PAYLOAD
    assert "Vehicle_Type" not in VALID_PUBLIC_PAYLOAD
    assert "Courier_Experience_yrs" not in VALID_PUBLIC_PAYLOAD


def test_risk_level_uses_metadata_threshold_boundaries():
    assert ml_app.classify_risk_level(0.39) == "Low"
    assert ml_app.classify_risk_level(0.40) == "Medium"
    assert ml_app.classify_risk_level(0.69) == "Medium"
    assert ml_app.classify_risk_level(0.70) == "High"


def test_validation_error_for_invalid_traffic_corridor_intensity():
    invalid_payload = {
        **VALID_PUBLIC_PAYLOAD,
        "traffic_corridor_intensity": "jammed",
    }

    response = client.post("/predict", json=invalid_payload)

    assert response.status_code == 422
    assert any(
        error["loc"][-1] == "traffic_corridor_intensity"
        for error in response.json()["detail"]
    )
