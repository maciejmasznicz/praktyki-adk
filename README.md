python3 -m venv .venv_adk

source .venv_adk/bin/activate

pip3 install --upgrade pip

python -m pip install \
"google-adk[extensions]" \
pandas \
python-dotenv \
mysql-connector-python \
sqlglot \
openpyxl \
xlrd

adk web

OPENROUTER_API_KEY=

MYSQL_HOST=
MYSQL_PORT=
MYSQL_USER=
MYSQL_PASSWORD=
MYSQL_DATABASE=

DATA_FILE_PATH=

SYSTEM_PROMPT_PATH=
