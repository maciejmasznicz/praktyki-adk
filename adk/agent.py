from google.adk.agents.llm_agent import Agent

from .config import MODEL_NAME, read_prompt
from .db_sub_agent.db_sub_agent import db_sub_agent
from .df_sub_agent.df_sub_agent import df_sub_agent


system_prompt = read_prompt("ROOT_AGENT_PROMPT")


root_agent = Agent(
    model=MODEL_NAME,
    name="root_agent",
    description=(
        "The main coordinator that routes requests to the correct "
        "database or file analysis sub-agent."
    ),
    instruction=system_prompt,
    sub_agents=[
        # temporary disable
        # db_sub_agent,
        df_sub_agent,
    ],
)