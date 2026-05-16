from pathlib import Path

import pandas as pd


BASE_DIR = Path(__file__).resolve().parents[1]

RAW_DATASET_PATH = BASE_DIR / "data" / "raw" / "Food_Delivery_Times.csv"
PROCESSED_DATASET_PATH = BASE_DIR / "data" / "processed" / "pulselocal_training_dataset.csv"

RISK_THRESHOLD_MINUTES = 45
REQUIRED_COLUMNS = {
    "Order_ID",
    "Distance_km",
    "Weather",
    "Traffic_Level",
    "Time_of_Day",
    "Vehicle_Type",
    "Preparation_Time_min",
    "Courier_Experience_yrs",
    "Delivery_Time_min",
}


def prepare_dataset(
    raw_dataset_path: Path = RAW_DATASET_PATH,
    processed_dataset_path: Path = PROCESSED_DATASET_PATH,
) -> pd.DataFrame:
    if not raw_dataset_path.exists():
        raise FileNotFoundError(f"Raw dataset not found: {raw_dataset_path}")

    df = pd.read_csv(raw_dataset_path)
    df.columns = df.columns.str.strip()

    missing_columns = REQUIRED_COLUMNS - set(df.columns)
    if missing_columns:
        raise ValueError(f"Missing required columns: {sorted(missing_columns)}")

    df["is_fulfillment_risky"] = (
        df["Delivery_Time_min"] > RISK_THRESHOLD_MINUTES
    ).astype(int)

    processed_dataset_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(processed_dataset_path, index=False)

    return df


def main() -> None:
    df = prepare_dataset()

    print(f"Created processed dataset: {PROCESSED_DATASET_PATH}")
    print(f"Shape: {df.shape}")

    print("\nTarget distribution:")
    print(df["is_fulfillment_risky"].value_counts())

    print("\nTarget distribution percentage:")
    print(df["is_fulfillment_risky"].value_counts(normalize=True))


if __name__ == "__main__":
    main()
