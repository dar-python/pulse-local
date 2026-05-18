from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import joblib

PROJECT_DIR = Path(__file__).resolve().parents[1]
if str(PROJECT_DIR) not in sys.path:
    sys.path.insert(0, str(PROJECT_DIR))

from app.main import MODEL_DIR, MODEL_PATH  # noqa: E402
from app.scenario_distribution import (  # noqa: E402
    evaluate_model_scenarios,
    summarize_distribution,
)


BASELINE_MODEL_PATH = MODEL_DIR / "pulselocal_logistic_regression_baseline_model.joblib"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run realistic PulseLocal demo scenarios through ML artifacts."
    )
    parser.add_argument(
        "--model-path",
        type=Path,
        default=MODEL_PATH,
        help="Primary model artifact to evaluate.",
    )
    parser.add_argument(
        "--baseline-path",
        type=Path,
        default=BASELINE_MODEL_PATH,
        help="Optional baseline model artifact to compare when present.",
    )
    args = parser.parse_args()

    model_paths = []
    if args.baseline_path.exists():
        model_paths.append(("baseline", args.baseline_path))
    model_paths.append(("active", args.model_path))

    for label, model_path in model_paths:
        print(f"\n=== {label}: {model_path} ===")
        model = joblib.load(model_path)
        rows = evaluate_model_scenarios(model)
        for row in rows:
            print(
                json.dumps(
                    {
                        "scenario": row["scenario"],
                        "features": row["features"],
                        "risk_score": row["risk_score"],
                        "risk_level": row["risk_level"],
                    },
                    sort_keys=True,
                )
            )

        print("summary:")
        print(json.dumps(summarize_distribution(rows), indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
