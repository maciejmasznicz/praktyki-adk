import os
from pathlib import Path

from dotenv import load_dotenv


load_dotenv(
    Path(__file__).parent / ".env.development"
)

prompt_path_from_env = os.getenv("SYSTEM_PROMPT_PATH")

if not prompt_path_from_env:
    raise ValueError(
        "SYSTEM_PROMPT_PATH is missing in .env.development"
    )


prompt_path = Path(prompt_path_from_env)

if not prompt_path.exists():
    raise FileNotFoundError(
        f"System prompt file does not exist: {prompt_path}"
    )


system_prompt = prompt_path.read_text(
    encoding="utf-8"
)


from google.adk.agents.llm_agent import Agent
from google.adk.models.lite_llm import LiteLlm

from .data_tools import read_data_file
from .sql_tools import (
    get_database_schema,
    execute_read_query,
)


root_agent = Agent(
    model=LiteLlm(
        model="openrouter/openai/gpt-5.6-luna"
    ),

    name="root_agent",

    description=(
        "An assistant that analyzes files and database data "
        "using safe read-only queries."
    ),

    instruction=system_prompt,

    tools=[
        read_data_file,
        get_database_schema,
        execute_read_query,
    ],
)