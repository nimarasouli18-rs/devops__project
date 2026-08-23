# syntax=docker/dockerfile:1

FROM python:3.12-slim-bookworm AS builder

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /build

COPY app/requirements.txt ./requirements.txt

RUN python -m pip wheel \
    --wheel-dir /wheels \
    --requirement requirements.txt


FROM python:3.12-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN groupadd \
        --gid 10001 \
        appgroup \
    && useradd \
        --uid 10001 \
        --gid 10001 \
        --home-dir /app \
        --no-create-home \
        --no-log-init \
        --shell /usr/sbin/nologin \
        appuser

WORKDIR /app

COPY --from=builder /wheels /wheels
COPY app/requirements.txt ./requirements.txt

RUN python -m pip install \
    --no-cache-dir \
    --no-index \
    --find-links=/wheels \
    --requirement requirements.txt \
    && rm -rf /wheels

COPY --chown=appuser:appgroup app/hello.py ./hello.py

USER appuser

EXPOSE 8000

CMD ["gunicorn", "--bind=0.0.0.0:8000", "--workers=1", "--timeout=60", "--access-logfile=-", "--error-logfile=-", "hello:server"]
