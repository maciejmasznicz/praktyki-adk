from google.adk.agents.llm_agent import Agent
from google.adk.models.lite_llm import LiteLlm

from ..config import MODEL_NAME, read_prompt
from .sql_tools import (
    get_database_schema,
    execute_read_query,
)


system_prompt = read_prompt("DB_SUB_AGENT_PROMPT")


db_sub_agent = Agent(
    model=LiteLlm(
        model=MODEL_NAME
    ),
    name="db_sub_agent",
    description=(
        "Handles only questions about the configured MySQL database. "
        "It must not analyze CSV, XLS, XLSX, Excel or spreadsheet files."
    ),
    instruction=system_prompt,
    tools=[
        get_database_schema,
        execute_read_query,
    ],
)