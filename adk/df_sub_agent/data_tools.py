import json
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv


load_dotenv(
    Path(__file__).resolve().parent.parent / ".env.development"
)

def read_data_file() -> dict:
    """
    Reads one CSV, XLS or XLSX file.
    The file path is loaded from .env.development.
    """

    file_path_from_env = os.getenv("DATA_FILE_PATH")

    if not file_path_from_env:
        return {
            "status": "error",
            "message": (
                "DATA_FILE_PATH is missing in "
                ".env.development."
            )
        }

    file_path = Path(file_path_from_env)

    if not file_path.exists():
        return {
            "status": "error",
            "message": (
                f"File does not exist: {file_path}"
            )
        }

    if not file_path.is_file():
        return {
            "status": "error",
            "message": (
                f"The selected path is not a file: {file_path}"
            )
        }

    file_extension = file_path.suffix.lower()

    if file_extension not in [".csv", ".xls", ".xlsx"]:
        return {
            "status": "error",
            "message": (
                "Only CSV, XLS and XLSX files are supported."
            )
        }

    try:
        if file_extension == ".csv":
            table = pd.read_csv(file_path)

        else:
            table = pd.read_excel(file_path)

        data = json.loads(
            table.to_json(
                orient="records",
                force_ascii=False
            )
        )

        return {
            "status": "success",
            "file_type": file_extension.upper().replace(".", ""),
            "data": data
        }

    except Exception as error:
        return {
            "status": "error",
            "message": str(error)
        }