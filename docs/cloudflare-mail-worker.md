# Cloudflare gpt-mail-worker (zone split, Grok-safe)

## Isolation

| Zone / resource | Owner | Status |
|---|---|---|
| `deltrivx.com` Email Routing catch-all | `grok-mail-worker` | **Frozen — do not change** |
| `mail.deltrivx.com` | Grok HTTP API | **Frozen** |
| `grok-mail-inbox` KV | Grok | **Frozen** |
| `deltrivx.ccwu.cc` Email Routing catch-all | `gpt-mail-worker` | GPT only |
| `gpt-mail.deltrivx.ccwu.cc` | GPT HTTP API | GPT only |
| `gpt-mail-inbox` KV | GPT | GPT only |

## Register-side env

```bash
MAIL_SOURCE=cf_temp
CF_API_URL=https://gpt-mail.deltrivx.ccwu.cc
CF_DOMAIN=deltrivx.ccwu.cc
CF_ADMIN_TOKEN=<worker API_KEY>
```

## Compatible API (mail_cf.py)

- `POST /admin/new_address` + header `x-admin-auth`
- `GET /admin/mails?address=<email>` + header `x-admin-auth`
- Response includes `email`/`address` and `jwt`/`token`
- List response includes `results` and `mails`

## Health

```bash
curl -sS https://gpt-mail.deltrivx.ccwu.cc/health
curl -sS https://mail.deltrivx.com/health   # Grok must remain ok
```

## Rollback (ccwu only)

If GPT mail misbehaves, restore **only** ccwu catch-all:

```text
PUT /zones/{ccwu_zone_id}/email/routing/rules/catch_all
actions: worker = grok-mail-worker
```

Never touch `deltrivx.com` for GPT work.
