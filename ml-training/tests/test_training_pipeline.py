import json

import pandas as pd

from scripts.prepare_dataset import prepare_dataset
from scripts.train_model import FEATURE_COLUMNS, TARGET_COLUMN, train_model


RAW_COLUMNS = [
    "Order_ID",
    "Distance_km",
    "Weather",
    "Traffic_Level",
    "Time_of_Day",
    "Vehicle_Type",
    "Preparation_Time_min",
    "Courier_Experience_yrs",
    "Delivery_Time_min",
]


def test_prepare_dataset_writes_processed_csv_with_risk_target(tmp_path):
    raw_path = tmp_path / "raw.csv"
    processed_path = tmp_path / "processed" / "dataset.csv"
    pd.DataFrame(
        [
            [1, 2.0, "clear", "low", "morning", "motorcycle", 10, 1.0, 30],
            [2, 5.0, "rainy", "high", "evening", "motorcycle", 35, 2.0, 70],
        ],
        columns=RAW_COLUMNS,
    ).to_csv(raw_path, index=False)

    df = prepare_dataset(raw_path, processed_path)

    assert processed_path.exists()
    assert df[TARGET_COLUMN].tolist() == [0, 1]


def test_train_model_exports_model_and_metadata_from_processed_dataset(tmp_path):
    processed_path = tmp_path / "processed.csv"
    artifacts_dir = tmp_path / "artifacts"
    pd.DataFrame(_processed_rows()).to_csv(processed_path, index=False)

    result = train_model(
        processed_dataset_path=processed_path,
        artifacts_dir=artifacts_dir,
        test_size=0.25,
        cv_splits=2,
    )

    assert result["model_path"].exists()
    assert result["metadata_path"].exists()

    metadata = json.loads(result["metadata_path"].read_text(encoding="utf-8"))
    assert metadata["target_column"] == TARGET_COLUMN
    assert metadata["model_type"] == "LogisticRegression"
    assert metadata["cross_validation"]["n_splits"] == 2
    assert "created_at" not in metadata


def test_training_features_do_not_include_outcome_or_prediction_columns():
    forbidden_features = {
        TARGET_COLUMN,
        "fulfillment_status",
        "delay_minutes",
        "failed_reason",
        "risk_level",
        "risk_score",
        "Delivery_Time_min",
    }

    assert forbidden_features.isdisjoint(FEATURE_COLUMNS)


def _processed_rows() -> list[dict[str, object]]:
    rows = []
    categories = [
        ("clear", "low", "morning", "bicycle", 0),
        ("rainy", "high", "evening", "motorcycle", 1),
        ("stormy", "high", "night", "motorcycle", 1),
        ("clear", "medium", "afternoon", "bicycle", 0),
    ]

    for index in range(12):
        weather, traffic, time_of_day, vehicle, target = categories[index % 4]
        rows.append(
            {
                "Order_ID": index + 1,
                "Distance_km": None if index == 0 else 2.0 + index,
                "Weather": None if index == 1 else weather,
                "Traffic_Level": traffic,
                "Time_of_Day": time_of_day,
                "Vehicle_Type": vehicle,
                "Preparation_Time_min": 10 + index,
                "Courier_Experience_yrs": 1.0 + (index % 3),
                "Delivery_Time_min": 30 + index,
                TARGET_COLUMN: target,
            }
        )

    return rows
