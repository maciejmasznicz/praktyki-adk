import os
from pathlib import Path

from dotenv import load_dotenv
from google.adk.agents.llm_agent import Agent
from google.adk.models.lite_llm import LiteLlm

from .sql_tools import (
    get_database_schema,
    execute_read_query,
)


env_path = Path(__file__).resolve().parent.parent / ".env.development"
load_dotenv(env_path)

prompt_path_from_env = os.getenv("DB_SUB_AGENT_PROMPT")

if not prompt_path_from_env:
    raise ValueError(
        "DB_SUB_AGENT_PROMPT is missing in .env.development"
    )

prompt_path = Path(prompt_path_from_env)

if not prompt_path.exists():
    raise FileNotFoundError(
        f"System prompt file does not exist: {prompt_path}"
    )

system_prompt = prompt_path.read_text(encoding="utf-8")


db_sub_agent = Agent(
    model=LiteLlm(
        model="openrouter/openai/gpt-5.6-luna"
        # model="ollama_chat/llama3.2:3b"
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