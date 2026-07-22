#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${DATA_DIR:-/data}"
APP_DIR="/app"
WEBUI_DIR="${APP_DIR}/webui"

mkdir -p "${DATA_DIR}/logs"

# Persist SQLite on the data volume (symlink if needed)
if [[ ! -e "${WEBUI_DIR}/webui.db" && ! -L "${WEBUI_DIR}/webui.db" ]]; then
  if [[ -f "${DATA_DIR}/webui.db" ]]; then
    ln -sfn "${DATA_DIR}/webui.db" "${WEBUI_DIR}/webui.db"
  else
    # create empty file on volume, then link
    : > "${DATA_DIR}/webui.db"
    ln -sfn "${DATA_DIR}/webui.db" "${WEBUI_DIR}/webui.db"
  fi
elif [[ -f "${WEBUI_DIR}/webui.db" && ! -L "${WEBUI_DIR}/webui.db" ]]; then
  # first-run local file -> move to volume
  if [[ ! -f "${DATA_DIR}/webui.db" ]]; then
    mv "${WEBUI_DIR}/webui.db" "${DATA_DIR}/webui.db"
  fi
  ln -sfn "${DATA_DIR}/webui.db" "${WEBUI_DIR}/webui.db"
fi

# Inject CF / mail settings from env into SQLite settings table (optional)
python - <<'PY'
import os
import sqlite3
from pathlib import Path

db = Path(os.environ.get("DATA_DIR", "/data")) / "webui.db"
db.parent.mkdir(parents=True, exist_ok=True)
con = sqlite3.connect(str(db))
con.execute(
    "CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)"
)

def put(k, v):
    if v is None:
        return
    v = str(v).strip()
    if not v:
        return
    con.execute(
        "INSERT INTO settings(key,value) VALUES(?,?) "
        "ON CONFLICT(key) DO UPDATE SET value=excluded.value",
        (k, v),
    )

mail_source = os.environ.get("MAIL_SOURCE", "").strip()
if mail_source:
    put("mail_source", mail_source)
put("cf_api_url", os.environ.get("CF_API_URL"))
put("cf_domain", os.environ.get("CF_DOMAIN"))
tok = os.environ.get("CF_ADMIN_TOKEN", "").strip()
if tok and tok not in ("***", "replace-with-worker-api-key"):
    put("cf_admin_token", tok)

con.commit()
con.close()
print(f"[entrypoint] data_dir={os.environ.get('DATA_DIR','/data')} mail settings injected (if provided)")
PY

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8765}"

# If user passed custom CMD, honor it; otherwise default start_webui args from env
if [[ $# -gt 0 ]]; then
  # rewrite default CMD host/port if it's the stock command
  if [[ "$1" == "python" && "${2:-}" == "start_webui.py" ]]; then
    exec python start_webui.py --host "${HOST}" --port "${PORT}" --no-browser
  fi
  exec "$@"
fi

exec python start_webui.py --host "${HOST}" --port "${PORT}" --no-browser
