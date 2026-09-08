import os
import zipfile
from datetime import date, datetime, time, timedelta
from decimal import Decimal
from pathlib import Path

import duckdb
import pandas as pd
import sqlglot
from dotenv import load_dotenv
from sqlglot import exp


ENV_PATH = Path(__file__).resolve().parent.parent / ".env.development"
load_dotenv(ENV_PATH)

DATA_TABLE = "data"
SUPPORTED_EXTENSIONS = {".csv", ".xls", ".xlsx"}
MAX_FILE_SIZE_BYTES = 50 * 1024 * 1024
MAX_XLSX_UNCOMPRESSED_BYTES = 200 * 1024 * 1024
MAX_ROWS = 200
MAX_COLUMNS = 200
MAX_QUERY_LENGTH = 10_000
MAX_SOURCE_ROWS = 100_000
MAX_JOINS = 8
MAX_RESULT_COLUMNS = 50
MAX_CELL_CHARACTERS = 2_000


def _error(message: str) -> dict:
    return {"status": "error", "message": message}


def _get_data_file_path() -> tuple[Path | None, str | None]:
    configured_path = os.getenv("DATA_FILE_PATH")

    if not configured_path:
        return None, "DATA_FILE_PATH is missing in .env.development."

    file_path = Path(configured_path)

    if not file_path.is_absolute():
        file_path = ENV_PATH.parent / file_path

    try:
        file_path = file_path.resolve(strict=True)
    except (OSError, RuntimeError):
        return None, "The configured data file does not exist."

    if not file_path.is_file():
        return None, "The configured data path is not a file."

    if file_path.suffix.lower() not in SUPPORTED_EXTENSIONS:
        return None, "Only CSV, XLS and XLSX files are supported."

    try:
        if file_path.stat().st_size > MAX_FILE_SIZE_BYTES:
            return None, "The configured data file exceeds the 50 MB limit."
    except OSError:
        return None, "The configured data file cannot be inspected."

    if file_path.suffix.lower() == ".xlsx":
        try:
            with zipfile.ZipFile(file_path) as archive:
                uncompressed_size = sum(info.file_size for info in archive.infolist())

            if uncompressed_size > MAX_XLSX_UNCOMPRESSED_BYTES:
                return None, "The uncompressed XLSX file exceeds the 200 MB limit."
        except (OSError, zipfile.BadZipFile):
            return None, "The configured XLSX file is invalid."

    return file_path, None


def _open_database() -> duckdb.DuckDBPyConnection:
    file_path, error_message = _get_data_file_path()

    if error_message or file_path is None:
        raise ValueError(error_message)

    connection = duckdb.connect(
        database=":memory:",
        config={
            "enable_external_access": "true",
            "memory_limit": "256MB",
            "threads": "2",
        },
    )

    try:
        if file_path.suffix.lower() == ".csv":
            relation = connection.read_csv(str(file_path), header=True)
            relation.create(DATA_TABLE)
        else:
            table = pd.read_excel(file_path, nrows=MAX_SOURCE_ROWS + 1)

            if len(table.index) > MAX_SOURCE_ROWS:
                raise ValueError(
                    "The configured spreadsheet exceeds the 100,000-row limit."
                )

            connection.register("source_table", table)
            connection.execute(
                f"CREATE TABLE {DATA_TABLE} AS SELECT * FROM source_table"
            )
            connection.unregister("source_table")

        column_count = connection.execute(
            "SELECT COUNT(*) FROM pragma_table_info(?)",
            [DATA_TABLE],
        ).fetchone()[0]

        if column_count > MAX_COLUMNS:
            raise ValueError("The configured data file exceeds the 200-column limit.")

        # Queries run only against the materialized in-memory table. Disabling
        # external access prevents SQL from reading or writing arbitrary files.
        connection.execute("SET enable_external_access = false")
        return connection
    except Exception:
        connection.close()
        raise


def _convert_value(value):
    if isinstance(value, Decimal):
        return str(value)

    if isinstance(value, (date, datetime, time)):
        return value.isoformat()

    if isinstance(value, timedelta):
        return str(value)

    if isinstance(value, bytes):
        return value.hex()[:MAX_CELL_CHARACTERS]

    if isinstance(value, str) and len(value) > MAX_CELL_CHARACTERS:
        return value[:MAX_CELL_CHARACTERS] + "…"

    return value


def _prepare_safe_query(query: str) -> tuple[str | None, str | None]:
    query = query.strip()

    if not query:
        return None, "The SQL query is empty."

    if len(query) > MAX_QUERY_LENGTH:
        return None, "The SQL query is too long."

    try:
        statements = [
            statement
            for statement in sqlglot.parse(query, read="duckdb")
            if statement
        ]
    except Exception:
        return None, "The SQL query is invalid."

    if len(statements) != 1:
        return None, "Only one SQL query is allowed."

    statement = statements[0]

    if not isinstance(statement, exp.Select):
        return None, "Only SELECT queries are allowed."

    if any(node.comments for node in statement.walk()):
        return None, "SQL comments are not allowed."

    if statement.find(exp.Anonymous):
        return None, "Unsupported SQL function detected."

    if len(list(statement.find_all(exp.Join))) > MAX_JOINS:
        return None, "The SQL query contains too many joins."

    with_clause = statement.args.get("with_")

    if with_clause and with_clause.args.get("recursive"):
        return None, "Recursive queries are not allowed."

    cte_names = {
        cte.alias_or_name.lower()
        for cte in statement.find_all(exp.CTE)
    }

    allowed_tables = {DATA_TABLE, *cte_names}

    for table in statement.find_all(exp.Table):
        if not isinstance(table.this, exp.Identifier):
            return None, "Table functions are not allowed."

        if table.catalog or table.db:
            return None, "Database and schema qualifiers are not allowed."

        if table.name.lower() not in allowed_tables:
            return None, f"Only the '{DATA_TABLE}' table may be queried."

    requested_limit = statement.args.get("limit")
    safe_limit = MAX_ROWS + 1

    if requested_limit:
        limit_expression = requested_limit.expression

        if not isinstance(limit_expression, exp.Literal) or limit_expression.is_string:
            return None, "LIMIT must be a non-negative integer."

        requested_value = int(limit_expression.this)

        if requested_value < 0:
            return None, "LIMIT must be a non-negative integer."

        safe_limit = min(requested_value, MAX_ROWS + 1)

    # Bound the result before Python receives rows while preserving a smaller
    # LIMIT explicitly requested by the model.
    safe_statement = statement.copy().limit(safe_limit)
    return safe_statement.sql(dialect="duckdb"), None


def get_data_schema() -> dict:
    """Returns column names, DuckDB types and the row count of the configured file."""

    connection = None

    try:
        connection = _open_database()
        columns = connection.execute(
            "SELECT name, type FROM pragma_table_info(?) ORDER BY cid",
            [DATA_TABLE],
        ).fetchall()
        row_count = connection.execute(
            f"SELECT COUNT(*) FROM {DATA_TABLE}"
        ).fetchone()[0]

        return {
            "status": "success",
            "table": DATA_TABLE,
            "columns": [
                {"name": name, "type": data_type}
                for name, data_type in columns
            ],
            "row_count": row_count,
        }
    except ValueError as error:
        return _error(str(error))
    except Exception:
        return _error("The configured data file could not be read.")
    finally:
        if connection:
            connection.close()


def execute_data_query(query: str) -> dict:
    """Executes one safe read-only DuckDB SELECT against the `data` table."""

    safe_query, error_message = _prepare_safe_query(query)

    if error_message or safe_query is None:
        return _error(error_message or "The SQL query is invalid.")

    connection = None

    try:
        connection = _open_database()
        cursor = connection.execute(safe_query)
        column_names = [column[0] for column in cursor.description]

        if len(column_names) != len(set(column_names)):
            return _error("Query result columns must have unique names or aliases.")

        if len(column_names) > MAX_RESULT_COLUMNS:
            return _error("The query result exceeds the 50-column limit.")

        rows = cursor.fetchall()
        too_many_rows = len(rows) > MAX_ROWS
        rows = rows[:MAX_ROWS]

        return {
            "status": "success",
            "rows": [
                {
                    name: _convert_value(value)
                    for name, value in zip(column_names, row)
                }
                for row in rows
            ],
            "row_count": len(rows),
            "limited_to": MAX_ROWS if too_many_rows else None,
        }
    except ValueError as error:
        return _error(str(error))
    except Exception:
        return _error("The data query could not be executed.")
    finally:
        if connection:
            connection.close()
