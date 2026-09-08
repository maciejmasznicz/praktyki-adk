```bash
python3 -m venv .venv_adk
source .venv_adk/bin/activate

python -m pip install -r requirements.txt

adk web
```

Plik `adk/.env.development`:

```env
OPENROUTER_API_KEY=

MYSQL_HOST=
MYSQL_PORT=
MYSQL_USER=
MYSQL_PASSWORD=
MYSQL_DATABASE=

DATA_FILE_PATH=

ROOT_AGENT_PROMPT=prompts/root_agent_prompt.md
DB_SUB_AGENT_PROMPT=prompts/db_sub_agent_prompt.md
DF_SUB_AGENT_PROMPT=prompts/df_sub_agent_prompt.md
```
