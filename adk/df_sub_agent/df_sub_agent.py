from google.adk.agents.llm_agent import Agent

from ..config import MODEL_NAME, read_prompt
from .data_tools import execute_data_query, get_data_schema


system_prompt = read_prompt("DF_SUB_AGENT_PROMPT")


df_sub_agent = Agent(
    model=MODEL_NAME,
    name="df_sub_agent",
    description=(
        "Handles only questions about the configured CSV, XLS or XLSX file. "
        "It must not analyze the PostgreSQL database."
    ),
    instruction=system_prompt,
    tools=[
        get_data_schema,
        execute_data_query,
    ],
)