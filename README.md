```bash
python3 -m venv .venv_adk
source .venv_adk/bin/activate

python -m pip install -r requirements.txt
```

Plik `adk/.env.development`:

```env
GOOGLE_CLOUD_PROJECT=
GOOGLE_CLOUD_LOCATION=
GOOGLE_GENAI_USE_ENTERPRISE=
MODEL_NAME=

DATA_FILE_PATH=

ROOT_AGENT_PROMPT=
DB_SUB_AGENT_PROMPT=
DF_SUB_AGENT_PROMPT=
```
