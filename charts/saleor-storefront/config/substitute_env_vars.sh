#!/usr/bin/env bash
# shellcheck disable=SC2002

replace_vars() {
    local to_replace=$1
    local replacement=$2
    local from_filepath=$3
    local to_filepath=$4

    if [[ "${replacement}" == "empty_string" ]]; then
        replacement=""
    fi

    echo "to_replace: ${to_replace}"
    echo "replacement: ${replacement}"
    echo "from_filepath: ${from_filepath}"
    echo "to_filepath: ${to_filepath}"

    sed "s|${to_replace}|${replacement}|g" "${from_filepath}" >"${to_filepath}"
}

main() {
    local app_js_base_filepath
    local service_worker_base_filepath
    local precache_manifest_base_filepath
    app_js_base_filepath="$(find /app -type f -iname 'app.*.js' -printf "%P")"
    precache_manifest_base_filepath="$(find /app -type f -iname 'precache-manifest.*.js' -printf "%P")"

    if [[ -z "${STATIC_URL}" ]]; then export STATIC_URL="empty_string"; fi
    if [[ -z "${API_URI}" ]]; then export API_URI="empty_string"; fi
    if [[ -z "${SENTRY_DSN}" ]]; then export SENTRY_DSN="empty_string"; fi
    if [[ -z "${SENTRY_APM}" ]]; then export SENTRY_APM="0.0"; fi
    if [[ -z "${DEMO_MODE}" ]]; then export DEMO_MODE="false"; fi
    if [[ -z "${GTM_ID}" ]]; then export GTM_ID=""; fi

    replace_vars "STATIC_URL" "${STATIC_URL}" "/app/index.html" "/etc/nginx/app/index.html.1"
    replace_vars "STATIC_URL" "${STATIC_URL}" "/app/${app_js_base_filepath}" "/etc/nginx/app/${app_js_base_filepath}.1"
    replace_vars "STATIC_URL" "${STATIC_URL}" "/app/service-worker.js" "/etc/nginx/app/service-worker.js"
    replace_vars "STATIC_URL" "${STATIC_URL}" "/app/${precache_manifest_base_filepath}" "/etc/nginx/app/${precache_manifest_base_filepath}"
    replace_vars "API_URI" "${API_URI}" "/etc/nginx/app/index.html.1" "/etc/nginx/app/index.html.2"
    replace_vars "API_URI" "${API_URI}" "/etc/nginx/app/${app_js_base_filepath}.1" "/etc/nginx/app/${app_js_base_filepath}.2"
    replace_vars "SENTRY_DSN" "${SENTRY_DSN}" "/etc/nginx/app/${app_js_base_filepath}.2" "/etc/nginx/app/${app_js_base_filepath}.3"
    replace_vars "SENTRY_APM" "${SENTRY_APM}" "/etc/nginx/app/${app_js_base_filepath}.3" "/etc/nginx/app/${app_js_base_filepath}.4"
    replace_vars "e.demoMode=!1" "e.demoMode=${DEMO_MODE}" "/etc/nginx/app/${app_js_base_filepath}.4" "/etc/nginx/app/${app_js_base_filepath}.5"
    replace_vars "GTM_ID" "${GTM_ID}" "/etc/nginx/app/${app_js_base_filepath}.5" "/etc/nginx/app/${app_js_base_filepath}.6"

    cp "/etc/nginx/app/index.html.2" "/etc/nginx/app/index.html"
    cp "/etc/nginx/app/${app_js_base_filepath}.6" "/etc/nginx/app/${app_js_base_filepath}"

    rm "/etc/nginx/app/index.html.1"
    rm "/etc/nginx/app/index.html.2"
    rm "/etc/nginx/app/${app_js_base_filepath}.1"
    rm "/etc/nginx/app/${app_js_base_filepath}.2"
    rm "/etc/nginx/app/${app_js_base_filepath}.3"
    rm "/etc/nginx/app/${app_js_base_filepath}.4"
    rm "/etc/nginx/app/${app_js_base_filepath}.5"
    rm "/etc/nginx/app/${app_js_base_filepath}.6"

    cat /etc/nginx/app/index.html | grep -oP '.{100,100}src=.{100,150}'
    cat "/etc/nginx/app/${app_js_base_filepath}" | grep -oP '.{100,100}n(n.s=360).{100,150}'
    cat "/etc/nginx/app/${app_js_base_filepath}" | grep -oP '.{100,100}e.apiUrl.{100,150}'
    cat "/etc/nginx/app/${app_js_base_filepath}" | grep -oP '.{100,100}e.sentryDsn.{100,150}'
    cat "/etc/nginx/app/${app_js_base_filepath}" | grep -oP '.{100,100}o=parseFloat.{100,150}'
    cat "/etc/nginx/app/${app_js_base_filepath}" | grep -oP '.{100,100}e.demoMode.{100,150}'
    cat "/etc/nginx/app/${app_js_base_filepath}" | grep -oP '.{100,100}gtmId:.{100,150}'
}

main
