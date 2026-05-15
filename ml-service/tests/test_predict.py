from fastapi.testclient import TestClient

from app import app


client = TestClient(app)


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
    assert response.json() == {"status": "healthy"}


def test_low_risk_prediction():
    response = client.post(
        "/predict",
        json={
            "rider_to_order_ratio": 0.90,
            "merchant_prep_time": 8,
            "traffic_level": "light",
            "weather_category": "clear",
            "delivery_distance_km": 1.5,
            "payment_method": "prepaid",
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "risk_score": 0.10,
        "risk_level": "Low",
        "recommendation": "Low fulfillment risk. Proceed with standard checkout.",
    }


def test_medium_risk_prediction():
    response = client.post(
        "/predict",
        json={
            "rider_to_order_ratio": 0.45,
            "merchant_prep_time": 10,
            "traffic_level": "moderate",
            "weather_category": "rainy",
            "delivery_distance_km": 2.0,
            "payment_method": "prepaid",
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "risk_score": 0.45,
        "risk_level": "Medium",
        "recommendation": "Moderate fulfillment risk. Show realistic ETA and monitor merchant readiness.",
    }


def test_high_risk_prediction():
    response = client.post(
        "/predict",
        json={
            "rider_to_order_ratio": 0.45,
            "merchant_prep_time": 25,
            "traffic_level": "heavy",
            "weather_category": "rainy",
            "delivery_distance_km": 4.2,
            "payment_method": "cod",
        },
    )

    assert response.status_code == 200
    assert response.json() == {
        "risk_score": 0.85,
        "risk_level": "High",
        "recommendation": "High fulfillment risk. Adjust ETA and notify merchant.",
    }


def test_validation_error_for_invalid_rider_to_order_ratio():
    response = client.post(
        "/predict",
        json={
            "rider_to_order_ratio": 1.25,
            "merchant_prep_time": 8,
            "traffic_level": "light",
            "weather_category": "clear",
            "delivery_distance_km": 1.5,
            "payment_method": "prepaid",
        },
    )

    assert response.status_code == 422
    assert any(
        error["loc"][-1] == "rider_to_order_ratio"
        for error in response.json()["detail"]
    )


def test_validation_error_for_invalid_traffic_level():
    response = client.post(
        "/predict",
        json={
            "rider_to_order_ratio": 0.75,
            "merchant_prep_time": 8,
            "traffic_level": "jammed",
            "weather_category": "clear",
            "delivery_distance_km": 1.5,
            "payment_method": "prepaid",
        },
    )

    assert response.status_code == 422
    assert any(
        error["loc"][-1] == "traffic_level" for error in response.json()["detail"]
    )
