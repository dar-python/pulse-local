import json
from pathlib import Path
from typing import Any

import joblib
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

try:
    from scripts.prepare_dataset import PROCESSED_DATASET_PATH, prepare_dataset
except ModuleNotFoundError:
    from prepare_dataset import PROCESSED_DATASET_PATH, prepare_dataset


BASE_DIR = Path(__file__).resolve().parents[1]

ARTIFACTS_DIR = BASE_DIR / "artifacts"
MODEL_ARTIFACT_PATH = ARTIFACTS_DIR / "pulselocal_logistic_regression_model.joblib"
BASELINE_MODEL_ARTIFACT_PATH = (
    ARTIFACTS_DIR / "pulselocal_logistic_regression_baseline_model.joblib"
)
METADATA_ARTIFACT_PATH = ARTIFACTS_DIR / "pulselocal_model_metadata.json"
CALIBRATION_METHOD = "sigmoid"
CALIBRATED_REGULARIZATION_C = 0.001
BASELINE_REGULARIZATION_C = 1.0

TARGET_COLUMN = "is_fulfillment_risky"
FEATURE_COLUMNS = [
    "Distance_km",
    "Weather",
    "Traffic_Level",
    "Time_of_Day",
    "Vehicle_Type",
    "Preparation_Time_min",
    "Courier_Experience_yrs",
]
NUMERIC_FEATURES = [
    "Distance_km",
    "Preparation_Time_min",
    "Courier_Experience_yrs",
]
CATEGORICAL_FEATURES = [
    "Weather",
    "Traffic_Level",
    "Time_of_Day",
    "Vehicle_Type",
]
RISK_THRESHOLDS = {
    "low": {"min": 0.0, "max": 0.39},
    "medium": {"min": 0.4, "max": 0.69},
    "high": {"min": 0.7, "max": 1.0},
}


def build_pipeline(
    *,
    calibrated: bool = True,
    calibration_cv_splits: int = 5,
    regularization_c: float = CALIBRATED_REGULARIZATION_C,
) -> Pipeline:
    numeric_transformer = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="median")),
            ("scaler", StandardScaler()),
        ]
    )
    categorical_transformer = Pipeline(
        steps=[
            ("imputer", SimpleImputer(strategy="most_frequent")),
            ("encoder", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
        ]
    )

    preprocessor = ColumnTransformer(
        transformers=[
            ("numeric", numeric_transformer, NUMERIC_FEATURES),
            ("categorical", categorical_transformer, CATEGORICAL_FEATURES),
        ]
    )

    classifier = LogisticRegression(
        max_iter=1000,
        random_state=42,
        C=regularization_c,
    )
    if calibrated:
        classifier = CalibratedClassifierCV(
            estimator=classifier,
            method=CALIBRATION_METHOD,
            cv=calibration_cv_splits,
        )

    return Pipeline(
        steps=[
            ("preprocessor", preprocessor),
            ("classifier", classifier),
        ]
    )


def train_model(
    processed_dataset_path: Path = PROCESSED_DATASET_PATH,
    artifacts_dir: Path = ARTIFACTS_DIR,
    test_size: float = 0.2,
    random_state: int = 42,
    cv_splits: int = 5,
) -> dict[str, Any]:
    if not processed_dataset_path.exists():
        prepare_dataset(processed_dataset_path=processed_dataset_path)

    df = pd.read_csv(processed_dataset_path)
    _validate_training_columns(df)

    x = df[FEATURE_COLUMNS]
    y = df[TARGET_COLUMN]

    if y.nunique() < 2:
        raise ValueError("Training target must contain at least two classes.")

    x_train, x_test, y_train, y_test = train_test_split(
        x,
        y,
        test_size=test_size,
        random_state=random_state,
        stratify=y,
    )

    calibration_cv_splits = _bounded_stratified_splits(y_train, cv_splits)

    baseline_pipeline = build_pipeline(
        calibrated=False,
        regularization_c=BASELINE_REGULARIZATION_C,
    )
    baseline_pipeline.fit(x_train, y_train)

    pipeline = build_pipeline(
        calibrated=True,
        calibration_cv_splits=calibration_cv_splits,
        regularization_c=CALIBRATED_REGULARIZATION_C,
    )
    pipeline.fit(x_train, y_train)

    y_pred = pipeline.predict(x_test)
    y_score = pipeline.predict_proba(x_test)[:, 1]
    metrics = _classification_metrics(y_test, y_pred, y_score)
    cross_validation = _cross_validation_summary(pipeline, x, y, cv_splits)

    baseline_y_pred = baseline_pipeline.predict(x_test)
    baseline_y_score = baseline_pipeline.predict_proba(x_test)[:, 1]
    baseline_metrics = _classification_metrics(
        y_test,
        baseline_y_pred,
        baseline_y_score,
    )
    baseline_cross_validation = _cross_validation_summary(
        baseline_pipeline,
        x,
        y,
        cv_splits,
    )

    artifacts_dir.mkdir(parents=True, exist_ok=True)
    model_path = artifacts_dir / MODEL_ARTIFACT_PATH.name
    baseline_model_path = artifacts_dir / BASELINE_MODEL_ARTIFACT_PATH.name
    metadata_path = artifacts_dir / METADATA_ARTIFACT_PATH.name

    joblib.dump(pipeline, model_path)
    joblib.dump(baseline_pipeline, baseline_model_path)

    metadata = {
        "model_name": "PulseLocal Logistic Regression Fulfillment Risk Model",
        "model_type": "LogisticRegression",
        "base_model_artifact": baseline_model_path.name,
        "calibration": {
            "enabled": True,
            "method": CALIBRATION_METHOD,
            "cv_splits": calibration_cv_splits,
            "calibrator": "CalibratedClassifierCV",
            "base_estimator": "LogisticRegression",
            "regularization_c": CALIBRATED_REGULARIZATION_C,
        },
        "target_column": TARGET_COLUMN,
        "features": FEATURE_COLUMNS,
        "numeric_features": NUMERIC_FEATURES,
        "categorical_features": CATEGORICAL_FEATURES,
        "risk_thresholds": RISK_THRESHOLDS,
        "test_metrics": metrics,
        "cross_validation": cross_validation,
        "baseline": {
            "model_type": "LogisticRegression",
            "calibration": {"enabled": False},
            "regularization_c": BASELINE_REGULARIZATION_C,
            "test_metrics": baseline_metrics,
            "cross_validation": baseline_cross_validation,
        },
    }
    metadata_path.write_text(json.dumps(metadata, indent=4) + "\n", encoding="utf-8")

    return {
        "model_path": model_path,
        "baseline_model_path": baseline_model_path,
        "metadata_path": metadata_path,
        "metrics": metrics,
        "cross_validation": cross_validation,
        "baseline_metrics": baseline_metrics,
        "baseline_cross_validation": baseline_cross_validation,
    }


def _validate_training_columns(df: pd.DataFrame) -> None:
    required_columns = set(FEATURE_COLUMNS) | {TARGET_COLUMN}
    missing_columns = required_columns - set(df.columns)
    if missing_columns:
        raise ValueError(f"Missing required training columns: {sorted(missing_columns)}")


def _classification_metrics(
    y_test: pd.Series,
    y_pred: Any,
    y_score: Any,
) -> dict[str, float]:
    return {
        "accuracy": round(float(accuracy_score(y_test, y_pred)), 4),
        "precision": round(float(precision_score(y_test, y_pred, zero_division=0)), 4),
        "recall": round(float(recall_score(y_test, y_pred, zero_division=0)), 4),
        "f1_score": round(float(f1_score(y_test, y_pred, zero_division=0)), 4),
        "roc_auc": round(float(roc_auc_score(y_test, y_score)), 4),
    }


def _cross_validation_summary(
    pipeline: Pipeline,
    x: pd.DataFrame,
    y: pd.Series,
    requested_splits: int,
) -> dict[str, Any]:
    min_class_count = int(y.value_counts().min())
    n_splits = min(requested_splits, min_class_count)

    if n_splits < 2:
        return {
            "method": "StratifiedKFold",
            "n_splits": 0,
            "mean_roc_auc": None,
            "std_roc_auc": None,
            "scores": [],
        }

    cv = StratifiedKFold(n_splits=n_splits, shuffle=True, random_state=42)
    scores = cross_val_score(pipeline, x, y, cv=cv, scoring="roc_auc")

    return {
        "method": "StratifiedKFold",
        "n_splits": n_splits,
        "mean_roc_auc": round(float(scores.mean()), 4),
        "std_roc_auc": round(float(scores.std()), 4),
        "scores": [round(float(score), 4) for score in scores],
    }


def _bounded_stratified_splits(y: pd.Series, requested_splits: int) -> int:
    min_class_count = int(y.value_counts().min())
    n_splits = min(requested_splits, min_class_count)

    if n_splits < 2:
        raise ValueError(
            "Calibration requires at least two examples from each target class."
        )

    return n_splits


def main() -> None:
    result = train_model()

    print(f"Created model artifact: {result['model_path']}")
    print(f"Created baseline model artifact: {result['baseline_model_path']}")
    print(f"Created metadata artifact: {result['metadata_path']}")
    print("Test metrics:")
    for key, value in result["metrics"].items():
        print(f"{key}: {value}")


if __name__ == "__main__":
    main()
