FROM node:10.23.0-buster-slim as builder

ARG STATIC_URL
ARG API_URI
ARG APP_MOUNT_URI

ENV \
    STATIC_URL=${STATIC_URL:-STATIC_URL} \
    API_URI=${API_URI:-API_URI} \
    APP_MOUNT_URI=${APP_MOUNT_URI:-APP_MOUNT_URI}

WORKDIR /app
COPY . .

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
RUN \
    node -v && \
    npm -v && \
    npm ci --loglevel warn && \
    NODE_ENV=production npx webpack \
      --optimize-minimize \
      --mode production \
      --no-cache \
      --no-stats \
      --progress \
      --no-color && \
    chown -R 101:0 /app

FROM nginxinc/nginx-unprivileged:1.18.0

ARG SHORT_SHA
ARG VERSION

LABEL \
    \
    \
    org.opencontainers.image.title="saleor-dashboard"                                        \
    org.opencontainers.image.description="Docker image for saleor dashboard k8s containers"  \
    org.opencontainers.image.url="ghcr.io/eirenauts/saleor-dashboard:${VERSION}"             \
    org.opencontainers.image.source="https://github.com/mirumee/saleor-dashboard"            \
    org.opencontainers.image.revision="${SHORT_SHA}"                                         \
    org.opencontainers.image.version="${VERSION}"                                            \
    org.opencontainers.image.authors="Eirenauts (https://github.com/eirenauts)"              \
    org.opencontainers.image.licenses="Apache 2.0"

COPY --from=builder /app/build/dashboard /app
WORKDIR /app
