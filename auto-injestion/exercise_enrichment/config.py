from pathlib import Path
from pydantic import BaseModel, Field
import os, yaml

class Settings(BaseModel):
    spring_project: Path = Path("../coachly-exercise-service")
    data_dir: Path = Path("data")
    ollama_url: str = "http://localhost:11434"
    model: str = "qwen3:4b-instruct"
    embedding_model: str = "embeddinggemma"
    database_url: str | None = None
    schema: str = "exercises"
    staging_schema: str = "exercises_staging"
    workers: int = 1
    max_records: int | None = None
    auto_promote: bool = False
    auto_accept_minimum: float = 0.85
    review_minimum: float = 0.65

    @classmethod
    def load(cls, path: Path | None = None, **overrides):
        values = {}
        env_file = Path(__file__).resolve().parents[1] / ".env"
        if env_file.exists():
            for line in env_file.read_text(encoding="utf-8").splitlines():
                if line.strip() and not line.lstrip().startswith("#") and "=" in line:
                    key, value = line.split("=", 1); os.environ.setdefault(key.strip(), value.strip().strip('"'))
        if path and path.exists():
            values = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        values.update({k: v for k, v in overrides.items() if v is not None})
        values.setdefault("database_url", os.getenv("DATABASE_URL") or _database_url_from_env())
        values.setdefault("ollama_url", os.getenv("OLLAMA_BASE_URL", "http://localhost:11434"))
        values.setdefault("model", os.getenv("OLLAMA_GENERATION_MODEL", "qwen3:4b-instruct"))
        return cls.model_validate(values)

def _database_url_from_env():
    name=os.getenv("COACHLY_DB_NAME"); host=os.getenv("COACHLY_DB_HOST")
    if not (name and host): return None
    from urllib.parse import quote_plus
    user=quote_plus(os.getenv("COACHLY_DB_USERNAME", "")); password=quote_plus(os.getenv("COACHLY_DB_PASSWORD", "")); port=os.getenv("COACHLY_DB_PORT", "5432")
    return f"postgresql://{user}:{password}@{host}:{port}/{name}"
