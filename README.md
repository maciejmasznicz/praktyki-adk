```bash
python3 -m venv .venv_adk
source .venv_adk/bin/activate

python -m pip install -r requirements.txt

adk web
```

---

.env.development w folderze adk

```env
OPENROUTER_API_KEY=

MYSQL_HOST=
MYSQL_PORT=
MYSQL_USER=
MYSQL_PASSWORD=
MYSQL_DATABASE=

DATA_FILE_PATH=

SYSTEM_PROMPT_PATH=
```
