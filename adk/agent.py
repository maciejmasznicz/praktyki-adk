import os
from pathlib import Path

from dotenv import load_dotenv
from google.adk.agents.llm_agent import Agent
from google.adk.models.lite_llm import LiteLlm

from .db_sub_agent.db_sub_agent import db_sub_agent
from .df_sub_agent.df_sub_agent import df_sub_agent


env_path = Path(__file__).resolve().parent / ".env.development"
load_dotenv(env_path)

prompt_path_from_env = os.getenv("ROOT_AGENT_PROMPT")

if not prompt_path_from_env:
    raise ValueError(
        "ROOT_AGENT_PROMPT is missing in .env.development"
    )

prompt_path = Path(prompt_path_from_env)

if not prompt_path.is_absolute():
    prompt_path = env_path.parent / prompt_path

if not prompt_path.exists():
    raise FileNotFoundError(
        f"System prompt file does not exist: {prompt_path}"
    )

system_prompt = prompt_path.read_text(encoding="utf-8")


root_agent = Agent(
    model=LiteLlm(
        model="openrouter/openai/gpt-5.6-luna"
        # model="ollama_chat/llama3.2:3b"
    ),
    name="root_agent",
    description=(
        "The main coordinator that routes requests to the correct "
        "database or file analysis sub-agent."
    ),
    instruction=system_prompt,
    sub_agents=[
        db_sub_agent,
        df_sub_agent,
    ],
)