# gpt-register-lite

Private lite packaging of [Regert888/gpt-outlook-register](https://github.com/Regert888/gpt-outlook-register) for **Docker / Compose / Unraid**.

- WebUI protocol register (no browser automation)
- Default mail: **Cloudflare `gpt-mail-worker`** on **`deltrivx.ccwu.cc`**
- **Grok isolation**: `deltrivx.com` + `grok-mail-worker` + `mail.deltrivx.com` are **not** used by this stack

> This project is for private ops only. Respect provider ToS and local law. No guarantees on registration success.

## Architecture

```text
Browser → WebUI :8765
            ├─ auth_flow / sentinel / curl_cffi
            ├─ mail: CF gpt-mail-worker (deltrivx.ccwu.cc)
            └─ optional: SMS + egress proxy

Cloudflare split:
  deltrivx.com      → grok-mail-worker   (frozen)
  deltrivx.ccwu.cc  → gpt-mail-worker    (this project)
```

## Environment

| Variable | Example | Notes |
|---|---|---|
| `MAIL_SOURCE` | `cf_temp` | or `outlook` |
| `CF_API_URL` | `https://gpt-mail.deltrivx.ccwu.cc` | gpt-mail-worker |
| `CF_DOMAIN` | `deltrivx.ccwu.cc` | GPT mail domain only |
| `CF_ADMIN_TOKEN` | `***` | Worker API key (secret) |
| `PROXY` | `http://192.168.31.10:7890` | recommended |
| `PORT` | `8765` | WebUI |
| `DATA_DIR` | `/data` | SQLite + logs |

Copy `.env.example` → `.env` and fill secrets. **Never commit `.env`.**

Entrypoint injects `MAIL_SOURCE` / `CF_*` into SQLite `settings` on start.

---

## Install methods

### 1) Docker

```bash
git clone git@github.com:deltrivx/gpt-register-lite.git
cd gpt-register-lite
cp .env.example .env
# edit .env — set CF_ADMIN_TOKEN and optional PROXY

docker build -t gpt-register-lite:local .
docker run -d --name gpt-register-lite \
  --restart unless-stopped \
  -p 8765:8765 \
  -v "$PWD/data:/data" \
  --env-file .env \
  gpt-register-lite:local
```

Open: `http://<host>:8765/`

Health:

```bash
curl -sS http://127.0.0.1:8765/ | head
curl -sS https://gpt-mail.deltrivx.ccwu.cc/health
```

Stop / logs:

```bash
docker logs -f gpt-register-lite
docker stop gpt-register-lite && docker rm gpt-register-lite
```

### 2) Docker Compose

```bash
git clone git@github.com:deltrivx/gpt-register-lite.git
cd gpt-register-lite
cp .env.example .env
# edit .env

docker compose up -d --build
docker compose logs -f
docker compose ps
```

Data: `./data` → container `/data` (`webui.db`, logs).

```bash
docker compose down          # stop
docker compose up -d --build # upgrade after git pull
```

### 3) Unraid template

1. On Unraid, clone private repo and build:

```bash
cd /mnt/user/appdata
git clone git@github.com:deltrivx/gpt-register-lite.git
cd gpt-register-lite
docker build -t gpt-register-lite:local .
```

2. Install template:

```bash
cp unraid/gpt-register-lite.xml \
  /boot/config/plugins/dockerMan/templates-user/my-gpt-register-lite.xml
```

3. Docker → Add Container → select template **gpt-register-lite**.

| Setting | Value |
|---|---|
| Repository | `gpt-register-lite:local` |
| Port | host `8765` → container `8765` |
| Path | `/mnt/user/appdata/gpt-register-lite` → `/data` |
| `MAIL_SOURCE` | `cf_temp` |
| `CF_API_URL` | `https://gpt-mail.deltrivx.ccwu.cc` |
| `CF_DOMAIN` | `deltrivx.ccwu.cc` |
| `CF_ADMIN_TOKEN` | worker API key (masked) |
| `PROXY` | optional, e.g. `http://192.168.31.10:7890` |
| `TZ` | `Asia/Shanghai` |

4. WebUI: `http://<unraid-ip>:8765/`

More detail: [docs/unraid.md](docs/unraid.md)

---

## Cloudflare mail notes

- Worker: `gpt-mail-worker`
- HTTP: `https://gpt-mail.deltrivx.ccwu.cc`
- Domain: `@deltrivx.ccwu.cc`
- APIs used by `mail_cf.py`:
  - `POST /admin/new_address` (`x-admin-auth`)
  - `GET /admin/mails?address=`
- **Do not** point this app at `mail.deltrivx.com` (Grok).

See [docs/cloudflare-mail-worker.md](docs/cloudflare-mail-worker.md).

## WebUI quick start

1. Open WebUI → **邮箱配置** → source `cf_temp` (pre-filled if env set)
2. Test CF connectivity
3. Optional: proxy / SMS tabs
4. Run a single registration first before auto-loop

## Data & secrets

| Path | Content |
|---|---|
| `/data/webui.db` | accounts, settings, results |
| `/data/logs` | optional logs |
| `.env` / Unraid env | tokens, proxy |

Ignored by git: `.env`, `data/`, `*.db`, account dumps.

## Upstream

App code under `app/` is a snapshot/packaging of the public protocol register project, plus:

- Docker image with **Node 20** (sentinel / OTP path)
- env → SQLite settings injection
- Unraid template + compose

## Security

- Private repo only
- Do not expose `:8765` to the public Internet without auth / tunnel ACL
- Never commit `CF_ADMIN_TOKEN`, SMS keys, or `webui.db`
