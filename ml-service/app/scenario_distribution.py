from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from statistics import mean
from typing import Any

from app.main import PredictionRequest, classify_risk_level, model_input_frame


@dataclass(frozen=True)
class DemoScenario:
    name: str
    payload: dict[str, Any]


DEMO_SCENARIOS = [
    DemoScenario(
        "Jollibee 1 item",
        {
            "Distance_km": 2.8,
            "Weather": "clear",
            "Traffic_Level": "low",
            "Time_of_Day": "afternoon",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 15,
            "Courier_Experience_yrs": 3.5,
        },
    ),
    DemoScenario(
        "Tambayan 2 items",
        {
            "Distance_km": 5.0,
            "Weather": "rainy",
            "Traffic_Level": "medium",
            "Time_of_Day": "evening",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 25,
            "Courier_Experience_yrs": 2.0,
        },
    ),
    DemoScenario(
        "Chao Fan 4 items",
        {
            "Distance_km": 6.6,
            "Weather": "stormy",
            "Traffic_Level": "high",
            "Time_of_Day": "night",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 35,
            "Courier_Experience_yrs": 1.0,
        },
    ),
    DemoScenario(
        "Low campus snack morning",
        {
            "Distance_km": 1.2,
            "Weather": "clear",
            "Traffic_Level": "low",
            "Time_of_Day": "morning",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 8,
            "Courier_Experience_yrs": 4.5,
        },
    ),
    DemoScenario(
        "Low bike nearby lunch",
        {
            "Distance_km": 1.8,
            "Weather": "clear",
            "Traffic_Level": "low",
            "Time_of_Day": "afternoon",
            "Vehicle_Type": "bicycle",
            "Preparation_Time_min": 10,
            "Courier_Experience_yrs": 3.0,
        },
    ),
    DemoScenario(
        "Medium drizzle lunch",
        {
            "Distance_km": 3.6,
            "Weather": "rainy",
            "Traffic_Level": "medium",
            "Time_of_Day": "afternoon",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 18,
            "Courier_Experience_yrs": 2.0,
        },
    ),
    DemoScenario(
        "Medium clear evening",
        {
            "Distance_km": 4.0,
            "Weather": "clear",
            "Traffic_Level": "medium",
            "Time_of_Day": "evening",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 22,
            "Courier_Experience_yrs": 2.5,
        },
    ),
    DemoScenario(
        "High rainy night far",
        {
            "Distance_km": 7.8,
            "Weather": "stormy",
            "Traffic_Level": "high",
            "Time_of_Day": "night",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 38,
            "Courier_Experience_yrs": 0.8,
        },
    ),
    DemoScenario(
        "High rush dinner big cart",
        {
            "Distance_km": 6.8,
            "Weather": "stormy",
            "Traffic_Level": "high",
            "Time_of_Day": "evening",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 40,
            "Courier_Experience_yrs": 1.2,
        },
    ),
    DemoScenario(
        "Low experienced clear short prep",
        {
            "Distance_km": 2.0,
            "Weather": "clear",
            "Traffic_Level": "low",
            "Time_of_Day": "morning",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 12,
            "Courier_Experience_yrs": 5.0,
        },
    ),
    DemoScenario(
        "Medium bike traffic",
        {
            "Distance_km": 3.2,
            "Weather": "clear",
            "Traffic_Level": "medium",
            "Time_of_Day": "evening",
            "Vehicle_Type": "bicycle",
            "Preparation_Time_min": 20,
            "Courier_Experience_yrs": 1.5,
        },
    ),
    DemoScenario(
        "Medium rainy short distance",
        {
            "Distance_km": 2.6,
            "Weather": "rainy",
            "Traffic_Level": "medium",
            "Time_of_Day": "morning",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 20,
            "Courier_Experience_yrs": 2.0,
        },
    ),
    DemoScenario(
        "High far clear night",
        {
            "Distance_km": 8.5,
            "Weather": "clear",
            "Traffic_Level": "high",
            "Time_of_Day": "night",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 30,
            "Courier_Experience_yrs": 1.0,
        },
    ),
    DemoScenario(
        "Medium far experienced",
        {
            "Distance_km": 5.5,
            "Weather": "clear",
            "Traffic_Level": "medium",
            "Time_of_Day": "afternoon",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 24,
            "Courier_Experience_yrs": 4.0,
        },
    ),
    DemoScenario(
        "Low close rainy veteran",
        {
            "Distance_km": 1.5,
            "Weather": "rainy",
            "Traffic_Level": "low",
            "Time_of_Day": "morning",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 10,
            "Courier_Experience_yrs": 5.0,
        },
    ),
    DemoScenario(
        "High rainy bike night",
        {
            "Distance_km": 7.0,
            "Weather": "stormy",
            "Traffic_Level": "high",
            "Time_of_Day": "night",
            "Vehicle_Type": "bicycle",
            "Preparation_Time_min": 32,
            "Courier_Experience_yrs": 0.5,
        },
    ),
    DemoScenario(
        "Medium windy afternoon",
        {
            "Distance_km": 4.4,
            "Weather": "clear",
            "Traffic_Level": "medium",
            "Time_of_Day": "afternoon",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 24,
            "Courier_Experience_yrs": 2.0,
        },
    ),
    DemoScenario(
        "High rainy very far",
        {
            "Distance_km": 10.0,
            "Weather": "stormy",
            "Traffic_Level": "high",
            "Time_of_Day": "evening",
            "Vehicle_Type": "motorcycle",
            "Preparation_Time_min": 45,
            "Courier_Experience_yrs": 0.5,
        },
    ),
]


def evaluate_model_scenarios(model: Any) -> list[dict[str, Any]]:
    rows = []

    for scenario in DEMO_SCENARIOS:
        payload = PredictionRequest(**scenario.payload)
        features = model_input_frame(payload)
        risk_score = round(float(model.predict_proba(features)[0][1]), 4)
        risk_level = classify_risk_level(risk_score)
        rows.append(
            {
                "scenario": scenario.name,
                "features": features.iloc[0].to_dict(),
                "risk_score": risk_score,
                "risk_level": risk_level,
            }
        )

    return rows


def summarize_distribution(rows: list[dict[str, Any]]) -> dict[str, Any]:
    scores = [float(row["risk_score"]) for row in rows]
    level_counts = Counter(row["risk_level"] for row in rows)

    return {
        "min_score": round(min(scores), 4),
        "max_score": round(max(scores), 4),
        "average_score": round(mean(scores), 4),
        "risk_level_counts": {
            "Low": level_counts["Low"],
            "Medium": level_counts["Medium"],
            "High": level_counts["High"],
        },
        "near_zero_count": sum(score <= 0.01 for score in scores),
        "near_one_count": sum(score >= 0.99 for score in scores),
    }
