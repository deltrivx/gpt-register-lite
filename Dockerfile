# gpt-register-lite
# Python WebUI + Node 20 (OpenAI sentinel QuickJS path)
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Asia/Shanghai \
    HOST=0.0.0.0 \
    PORT=8765 \
    DATA_DIR=/data \
    DEBIAN_FRONTEND=noninteractive

# System deps + Node 20 (required for sentinel / OTP reliability)
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg tzdata \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
         | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
         > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/* \
    && node --version && npm --version

WORKDIR /app

# App source (upstream snapshot + lite packaging)
COPY app/requirements.txt /app/requirements.txt
RUN pip install --upgrade pip \
    && pip install -r /app/requirements.txt

COPY app/ /app/
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh \
    && mkdir -p /data \
    && useradd --create-home --shell /bin/bash appuser \
    && chown -R appuser:appuser /app /data

USER appuser

EXPOSE 8765

HEALTHCHECK --interval=30s --timeout=8s --start-period=40s --retries=3 \
  CMD python -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:%s/'%os.environ.get('PORT','8765'), timeout=5)" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "start_webui.py", "--host", "0.0.0.0", "--port", "8765", "--no-browser"]
