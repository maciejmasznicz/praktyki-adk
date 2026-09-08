from datetime import date, datetime, time, timedelta
from decimal import Decimal

import mysql.connector
import sqlglot
from sqlglot import exp

from ..config import get_setting


MAX_ROWS = 200
MAX_QUERY_LENGTH = 10_000
MAX_JOINS = 8
MAX_RESULT_COLUMNS = 50
MAX_CELL_CHARACTERS = 2_000


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
    """Connects to the database."""

    return mysql.connector.connect(
        host=get_setting("MYSQL_HOST"),
        port=int(get_setting("MYSQL_PORT", "3306") or "3306"),
        user=get_setting("MYSQL_USER"),
        password=get_setting("MYSQL_PASSWORD"),
        database=get_setting("MYSQL_DATABASE"),
        connection_timeout=10,
    )


def get_database_schema() -> dict:
    """Returns all tables and columns from the database."""

    connection = None
    cursor = None

    try:
        connection = connect_to_database()
        cursor = connection.cursor()

        cursor.execute("SHOW TABLES")

        tables = cursor.fetchall()
        schema = {}

        for table in tables:
            table_name = table[0]
            escaped_table_name = str(table_name).replace("`", "``")

            cursor.execute(
                f"DESCRIBE `{escaped_table_name}`"
            )

            columns = cursor.fetchall()

            schema[table_name] = [
                column[0]
                for column in columns
            ]

        return {
            "status": "success",
            "schema": schema,
        }

    except Exception:
        return {
            "status": "error",
            "message": "The database schema could not be read.",
        }

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()


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
            read="mysql"
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

    for table in statement.find_all(exp.Table):
        if table.catalog or table.db:
            return False, "Cross-database queries are not allowed."

    return True, ""


def prepare_limited_query(query: str) -> str:
    """Applies a hard result limit while preserving a smaller literal LIMIT."""

    statement = sqlglot.parse_one(query, read="mysql")
    requested_limit = statement.args.get("limit")
    safe_limit = MAX_ROWS + 1

    if requested_limit:
        limit_expression = requested_limit.expression

        if isinstance(limit_expression, exp.Literal) and not limit_expression.is_string:
            safe_limit = min(int(limit_expression.this), MAX_ROWS + 1)

    return statement.copy().limit(safe_limit).sql(dialect="mysql")


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

    except Exception:
        return {
            "status": "error",
            "message": "The database query could not be executed.",
        }

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()