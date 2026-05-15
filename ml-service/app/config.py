from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "PulseLocal ML Service"
    app_env: str = "local"
    app_host: str = "0.0.0.0"
    app_port: int = 8001
    log_level: str = "debug"

    mock_prediction_enabled: bool = True
    model_path: str = "./models/fulfillment_risk_model.joblib"

    risk_low_max: float = 0.39
    risk_medium_max: float = 0.69
    risk_high_min: float = 0.70

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )


settings = Settings()
