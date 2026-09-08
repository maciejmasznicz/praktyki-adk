import os
from pathlib import Path

from dotenv import load_dotenv


PACKAGE_DIR = Path(__file__).resolve().parent
ENV_PATH = PACKAGE_DIR / ".env.development"
MODEL_NAME = "openrouter/openai/gpt-5.6-luna"

load_dotenv(ENV_PATH)


def get_setting(name: str, default: str | None = None) -> str | None:
    """Returns one application setting loaded from the environment."""

    return os.getenv(name, default)


def read_prompt(variable_name: str) -> str:
    """Loads a UTF-8 prompt configured by an environment variable."""

    configured_path = get_setting(variable_name)

    if not configured_path:
        raise ValueError(f"{variable_name} is missing in .env.development")

    prompt_path = Path(configured_path)

    if not prompt_path.is_absolute():
        prompt_path = PACKAGE_DIR / prompt_path

    if not prompt_path.is_file():
        raise FileNotFoundError(f"Configured prompt does not exist: {variable_name}")

    return prompt_path.read_text(encoding="utf-8")