FROM node:10.23.0-buster-slim as builder

ARG API_URI
ARG SENTRY_DSN
ARG SENTRY_APM
ARG DEMO_MODE
ARG GTM_ID

ENV \
    STATIC_URL=${STATIC_URL:-STATIC_URL} \
    API_URI=${API_URI:-API_URI} \
    SENTRY_DSN=${SENTRY_DSN:-SENTRY_DSN} \
    SENTRY_APM=${SENTRY_APM:-SENTRY_APM} \
    DEMO_MODE=${DEMO_MODE:-DEMO_MODE} \
    GTM_ID=${GTM_ID:-GTM_ID}

WORKDIR /app
COPY . .

SHELL ["/bin/bash", "-e", "-o", "pipefail", "-c"]
RUN \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        bzip2='1.0.6-9.2~deb10u1' && \
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
    rm /app/dist/*.css.map && \
    rm /app/dist/js/*.js.map && \
    chown -R 101:0 /app

FROM nginxinc/nginx-unprivileged:1.18.0

ARG SHORT_SHA
ARG VERSION

LABEL \
    \
    \
    org.opencontainers.image.title="saleor-storefront"                                       \
    org.opencontainers.image.description="Docker image for saleor storefront k8s containers" \
    org.opencontainers.image.url="ghcr.io/eirenauts/saleor-storefront:${VERSION}"            \
    org.opencontainers.image.source="https://github.com/mirumee/saleor-storefront"           \
    org.opencontainers.image.revision="${SHORT_SHA}"                                         \
    org.opencontainers.image.version="${VERSION}"                                            \
    org.opencontainers.image.authors="Eirenauts (https://github.com/eirenauts)"              \
    org.opencontainers.image.licenses="Apache 2.0"

COPY --from=builder /app/dist /app
WORKDIR /app
