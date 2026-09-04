import os
import re
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path

import mysql.connector
import sqlglot
from dotenv import load_dotenv


load_dotenv(
    Path(__file__).parent / ".env.development"
)


MAX_ROWS = 200


def convert_to_json(value):
    """Converts database values to JSON-compatible values."""

    if isinstance(value, Decimal):
        return float(value)

    if isinstance(value, (date, datetime)):
        return value.isoformat()

    return value


def connect_to_database():
    """Connects to the database."""

    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        database=os.getenv("MYSQL_DATABASE"),
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

            cursor.execute(
                f"DESCRIBE `{table_name}`"
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

    except Exception as error:
        return {
            "status": "error",
            "message": str(error),
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

    if ";" in query:
        return False, (
            "Only one SQL query is allowed."
        )

    if (
        "--" in query
        or "#" in query
        or "/*" in query
        or "*/" in query
    ):
        return False, (
            "SQL comments are not allowed."
        )

    if not (
        query.lower().startswith("select")
        or query.lower().startswith("with")
    ):
        return False, (
            "Only SELECT queries are allowed."
        )

    forbidden_words = [
        r"\binsert\b",
        r"\bupdate\b",
        r"\bdelete\b",
        r"\bdrop\b",
        r"\balter\b",
        r"\bcreate\b",
        r"\btruncate\b",
        r"\breplace\b",
        r"\bgrant\b",
        r"\brevoke\b",
        r"\bset\b",
        r"\bcall\b",
        r"\bload\b",
        r"\block\b",
        r"\bunlock\b",
        r"\bcommit\b",
        r"\brollback\b",
        r"\boutfile\b",
        r"\bdumpfile\b",
    ]

    for forbidden_word in forbidden_words:
        if re.search(
            forbidden_word,
            query,
            re.IGNORECASE
        ):
            return False, (
                "Forbidden SQL command detected: "
                f"{forbidden_word}"
            )

    if re.search(
        r"\bfor\s+update\b",
        query,
        re.IGNORECASE
    ):
        return False, (
            "FOR UPDATE is not allowed."
        )

    try:
        sqlglot.parse_one(
            query,
            read="mysql"
        )

    except Exception as error:
        return False, (
            f"Invalid SQL query: {error}"
        )

    return True, ""


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

        cursor.execute(query)

        rows = cursor.fetchmany(MAX_ROWS + 1)

        column_names = [
            column[0]
            for column in cursor.description
        ]

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
            "message": str(error),
        }

    finally:
        if cursor:
            cursor.close()

        if connection:
            connection.close()