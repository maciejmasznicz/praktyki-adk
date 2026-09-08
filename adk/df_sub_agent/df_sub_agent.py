import os
from pathlib import Path

from dotenv import load_dotenv
from google.adk.agents.llm_agent import Agent
from google.adk.models.lite_llm import LiteLlm

from .data_tools import read_data_file


env_path = Path(__file__).resolve().parent.parent / ".env.development"
load_dotenv(env_path)

prompt_path_from_env = os.getenv("DF_SUB_AGENT_PROMPT")

if not prompt_path_from_env:
    raise ValueError(
        "DF_SUB_AGENT_PROMPT is missing in .env.development"
    )

prompt_path = Path(prompt_path_from_env)

if not prompt_path.exists():
    raise FileNotFoundError(
        f"System prompt file does not exist: {prompt_path}"
    )

system_prompt = prompt_path.read_text(encoding="utf-8")


df_sub_agent = Agent(
    model=LiteLlm(
        model="openrouter/openai/gpt-5.6-luna"
        # model="ollama_chat/llama3.2:3b"
    ),
    name="df_sub_agent",
    description=(
        "Handles only questions about the configured CSV, XLS or XLSX file. "
        "It must not analyze the MySQL database."
    ),
    instruction=system_prompt,
    tools=[
        read_data_file,
    ],
)