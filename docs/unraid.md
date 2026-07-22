# Unraid install

## 1. Build image on Unraid (private repo)

```bash
# on Unraid shell (example)
cd /mnt/user/appdata
gh auth status   # or use deploy key / PAT with repo scope
git clone git@github.com:deltrivx/gpt-register-lite.git
cd gpt-register-lite
docker build -t gpt-register-lite:local .
```

## 2. Template

Copy `unraid/gpt-register-lite.xml` to:

```text
/boot/config/plugins/dockerMan/templates-user/my-gpt-register-lite.xml
```

Then Docker tab → Add Container → Template `gpt-register-lite`.

## 3. Required settings

| Item | Value |
|---|---|
| Repository | `gpt-register-lite:local` |
| Port | `8765` |
| Path | `/mnt/user/appdata/gpt-register-lite` → `/data` |
| `MAIL_SOURCE` | `cf_temp` |
| `CF_API_URL` | `https://gpt-mail.deltrivx.ccwu.cc` |
| `CF_DOMAIN` | `deltrivx.ccwu.cc` |
| `CF_ADMIN_TOKEN` | worker admin key (masked) |
| `PROXY` | optional, e.g. `http://192.168.31.10:7890` |

## 4. Open WebUI

`http://<unraid-ip>:8765/`

Email tab should already show CF settings if env was injected.

## 5. Safety

- Keep WebUI on LAN / VPN only; do not expose 8765 publicly without auth.
- Grok mail on `deltrivx.com` is independent — do not point this stack at `mail.deltrivx.com`.
