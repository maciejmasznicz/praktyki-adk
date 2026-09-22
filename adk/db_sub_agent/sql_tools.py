from datetime import date, datetime, time, timedelta
from decimal import Decimal

import psycopg
import sqlglot
from psycopg import errors as psycopg_errors
from sqlglot import exp

from ..config import get_setting


MAX_ROWS = 200
MAX_QUERY_LENGTH = 10_000
MAX_JOINS = 8
MAX_RESULT_COLUMNS = 50
MAX_CELL_CHARACTERS = 2_000
DB_STATEMENT_TIMEOUT_MS = 15_000


def convert_to_json(value):
    """Converts database values to JSON-compatible values."""

    if isinstance(value, Decimal):
        return str(value)

    if isinstance(value, (date, datetime)):
        return value.isoformat()

    if isinstance(value, time):
        return value.isoformat()

    if isinstance(value, timedelta):
        return str(value)

    if isinstance(value, bytes):
        return value.hex()[:MAX_CELL_CHARACTERS]

    if isinstance(value, str) and len(value) > MAX_CELL_CHARACTERS:
        return value[:MAX_CELL_CHARACTERS] + "…"

    return value


def connect_to_database():
    """Connects to the PostgreSQL database in Cloud SQL."""

    return psycopg.connect(
        host=get_setting("POSTGRES_HOST"),
        port=int(get_setting("POSTGRES_PORT", "5432") or "5432"),
        user=get_setting("POSTGRES_USER"),
        password=get_setting("POSTGRES_PASSWORD"),
        dbname=get_setting("POSTGRES_DATABASE"),
        connect_timeout=10,
        sslmode=get_setting("POSTGRES_SSLMODE", "require"),
        application_name="adk-read-only-agent",
        options=(
            "-c default_transaction_read_only=on "
            f"-c statement_timeout={DB_STATEMENT_TIMEOUT_MS} "
            "-c idle_in_transaction_session_timeout=30000"
        ),
    )


def get_database_schema_name() -> str:
    """Returns the application schema allowed for database queries."""

    return get_setting("POSTGRES_SCHEMA", "public") or "public"


def _database_error_message(error: Exception, operation: str) -> str:
    """Returns an actionable database error without exposing credentials."""

    if isinstance(error, psycopg_errors.OperationalError):
        return (
            f"The database {operation} failed because PostgreSQL is unreachable. "
            "Check Cloud SQL Authorized networks and the deployed connection settings."
        )

    if isinstance(error, psycopg_errors.InvalidPassword):
        return "The database login failed. Check POSTGRES_USER and POSTGRES_PASSWORD."

    if isinstance(error, psycopg_errors.InvalidCatalogName):
        return "The configured PostgreSQL database does not exist."

    if isinstance(error, psycopg_errors.InsufficientPrivilege):
        return "The PostgreSQL user does not have sufficient read permissions."

    if isinstance(error, psycopg_errors.QueryCanceled):
        return "The database query exceeded the 15-second execution limit."

    if isinstance(error, psycopg_errors.UndefinedTable):
        return "The requested table does not exist in the configured schema."

    return f"The database {operation} failed. Check the table names and PostgreSQL configuration."


def get_database_schema() -> dict:
    """Returns all tables and columns from the database."""

    connection = None
    cursor = None

    try:
        connection = connect_to_database()
        cursor = connection.cursor()

        cursor.execute(
            """
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = %s
              AND table_type = 'BASE TABLE'
            ORDER BY table_name
            """,
            (get_database_schema_name(),),
        )

        tables = cursor.fetchall()
        schema = {}

        for table in tables:
            table_name = table[0]
            cursor.execute(
                """
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = %s
                  AND table_name = %s
                ORDER BY ordinal_position
                """,
                (get_database_schema_name(), table_name),
            )

            schema[table_name] = [column[0] for column in cursor.fetchall()]

        return {"status": "success", "schema": schema}

    except Exception as error:
        return {
            "status": "error",
            "message": _database_error_message(error, "schema read"),
        }

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()


def _validate_query_schema(query: str) -> tuple[bool, str]:
    """Allows unqualified names and the configured PostgreSQL schema only."""

    statement = sqlglot.parse_one(query, read="postgres")
    allowed_schema = get_database_schema_name()

    for table in statement.find_all(exp.Table):
        if table.catalog:
            return False, "Cross-database queries are not allowed."

        if table.db and str(table.db).strip('"') != allowed_schema:
            return False, "Queries outside the configured schema are not allowed."

    return True, ""


def is_safe_read_query(query: str) -> tuple[bool, str]:
    """
    Allows only safe read-only SQL queries.
    """

    query = query.strip()

    if not query:
        return False, "The SQL query is empty."

    if len(query) > MAX_QUERY_LENGTH:
        return False, "The SQL query is too long."

    try:
        statements = sqlglot.parse(
            query,
            read="postgres"
        )

    except Exception as error:
        return False, (
            f"Invalid SQL query: {error}"
        )

    statements = [statement for statement in statements if statement]

    if len(statements) != 1:
        return False, "Only one SQL query is allowed."

    statement = statements[0]

    if not isinstance(statement, exp.Select):
        return False, "Only SELECT queries are allowed."

    if any(node.comments for node in statement.walk()):
        return False, "SQL comments are not allowed."

    if statement.find(exp.Lock):
        return False, "Locking reads are not allowed."

    if statement.find(exp.Into):
        return False, "SELECT INTO is not allowed."

    if statement.find(exp.Anonymous):
        return False, "Unsupported SQL function detected."

    if len(list(statement.find_all(exp.Join))) > MAX_JOINS:
        return False, "The SQL query contains too many joins."

    if any(
        with_clause.args.get("recursive")
        for with_clause in statement.find_all(exp.With)
    ):
        return False, "Recursive queries are not allowed."

    schema_is_safe, schema_error = _validate_query_schema(query)

    if not schema_is_safe:
        return False, schema_error

    return True, ""


def prepare_limited_query(query: str) -> str:
    """Applies a hard result limit while preserving a smaller literal LIMIT."""

    statement = sqlglot.parse_one(query, read="postgres")
    requested_limit = statement.args.get("limit")
    safe_limit = MAX_ROWS + 1

    if requested_limit:
        limit_expression = requested_limit.expression

        if isinstance(limit_expression, exp.Literal) and not limit_expression.is_string:
            safe_limit = min(int(limit_expression.this), MAX_ROWS + 1)

    return statement.copy().limit(safe_limit).sql(dialect="postgres")


def execute_read_query(query: str) -> dict:
    """
    Executes one safe read-only SQL query.

    JOIN, WHERE, GROUP BY, ORDER BY,
    HAVING, COUNT, SUM, AVG, MIN and MAX
    are allowed.
    """

    is_safe, error_message = is_safe_read_query(query)

    if not is_safe:
        return {
            "status": "error",
            "message": error_message,
        }

    connection = None
    cursor = None

    try:
        connection = connect_to_database()
        cursor = connection.cursor()

        cursor.execute(prepare_limited_query(query))

        rows = cursor.fetchmany(MAX_ROWS + 1)

        column_names = [
            column[0]
            for column in cursor.description
        ]

        if len(column_names) != len(set(column_names)):
            return {
                "status": "error",
                "message": "Query result columns must have unique names or aliases.",
            }

        if len(column_names) > MAX_RESULT_COLUMNS:
            return {
                "status": "error",
                "message": "The query result exceeds the 50-column limit.",
            }

        too_many_rows = len(rows) > MAX_ROWS

        rows = rows[:MAX_ROWS]

        data = [
            {
                column_name: convert_to_json(value)
                for column_name, value in zip(
                    column_names,
                    row
                )
            }
            for row in rows
        ]

        return {
            "status": "success",
            "rows": data,
            "row_count": len(data),
            "limited_to": (
                MAX_ROWS
                if too_many_rows
                else None
            ),
        }

    except Exception as error:
        return {
            "status": "error",
            "message": _database_error_message(error, "query execution"),
        }

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()