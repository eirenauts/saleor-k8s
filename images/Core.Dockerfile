FROM python:3.8.6 as build-python

COPY requirements*.txt /app/
WORKDIR /app

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
RUN \
    apt-get update -y && \
    apt-get install -y --no-install-recommends gettext='0.19.8.1-9' && \
    echo "About to install requirements.txt for saleor" && \
    pip install -r requirements.txt

FROM python:3.8.6-slim
ARG SHORT_SHA
ARG VERSION
ARG UID=1001
ARG GUID=1001

ENV \
    \
    \
    GUNICORN_LOG_LEVEL=${GUNICORN_LOG_LEVEL:--} \
    GUNICORN_FORWARDED_ALLOW_IPS=${GUNICORN_FORWARDED_ALLOW_IPS:-127.0.0.1} \
    GUNICORN_PROXY_ALLOW_IPS=${GUNICORN_PROXY_ALLOW_IPS:-127.0.0.1} \
    GUNICORN_BIND_HOST=${GUNICORN_BIND_HOST:-0.0.0.0} \
    GUNICORN_BIND_PORT=${GUNICORN_BIND_PORT:-8000} \
    GUNICORN_BACKLOG=${GUNICORN_BACKLOG:-1024} \
    GUNICORN_WORKER_PROCESSES=${GUNICORN_WORKER_PROCESSES:-2} \
    GUNICORN_WORKER_CLASS=${GUNICORN_WORKER_CLASS:-uvicorn.workers.UvicornWorker} \
    GUNICORN_THREADS_PER_WORKER=${GUNICORN_THREADS_PER_WORKER:-1} \
    GUNICORN_MAX_WORKER_CONNECTIONS=${GUNICORN_MAX_WORKER_CONNECTIONS:-200} \
    GUNICORN_SILENT_WORKER_TIMEOUT=${GUNICORN_SILENT_WORKER_TIMEOUT:-30} \
    GUNICORN_WORKER_RESTART_GRACEFUL_TIMEOUT=${GUNICORN_WORKER_RESTART_GRACEFUL_TIMEOUT:-60} \
    GUNICORN_CONNECTION_KEEP_ALIVE=${GUNICORN_CONNECTION_KEEP_ALIVE:-5} \
    RESTIC_DOWNLOAD_URL=https://github.com/restic/restic/releases/download \
    RESTIC_VERSION=0.11.0

LABEL \
    \
    \
    org.opencontainers.image.title="saleor-core"                                             \
    org.opencontainers.image.description="Docker image for saleor core k8s containers"       \
    org.opencontainers.image.url="ghcr.io/eirenauts/saleor-core:${VERSION}"                  \
    org.opencontainers.image.source="https://github.com/mirumee/saleor"                      \
    org.opencontainers.image.revision="${SHORT_SHA}"                                         \
    org.opencontainers.image.version="${VERSION}"                                            \
    org.opencontainers.image.authors="Eirenauts (https://github.com/eirenauts)"              \
    org.opencontainers.image.licenses="Apache 2.0"


COPY . /app
COPY --from=build-python /usr/local/lib/python3.8/site-packages/ /usr/local/lib/python3.8/site-packages/
COPY --from=build-python /usr/local/bin/ /usr/local/bin/
WORKDIR /app

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
RUN \
    apt-get update -y && \
    apt-get install -y --no-install-recommends --allow-downgrades \
      libxml2='2.9.4+dfsg1-7+deb10u2' \
      libssl1.1='1.1.1d-0+deb10u6' \
      libcairo2='1.16.0-4+deb10u1' \
      libpango-1.0-0='1.42.4-8~deb10u1' \
      libpangocairo-1.0-0='1.42.4-8~deb10u1' \
      libgdk-pixbuf2.0-0='2.38.1+dfsg-1' \
      libmagic1='1:5.35-4+deb10u2' \
      shared-mime-info='1.10-1' \
      mime-support='3.62' && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --system --gid "${GUID}" saleor && \
    useradd --uid "${UID}" --gid "${GUID}" --create-home saleor && \
    mkdir -p /app/media /app/static && \
    chown -R "${UID}:0" /app
USER "${UID}"
EXPOSE 8000

CMD ["gunicorn", "-c", "/app/saleor/gunicorn_conf.py", "saleor.asgi:application"]
