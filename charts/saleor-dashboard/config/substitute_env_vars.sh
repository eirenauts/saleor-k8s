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
    local dashboard_js_base_filepath
    dashboard_js_base_filepath="$(find /app -type f -iname 'dashboard.*.js' -printf "%P")"

    if [[ -z "${STATIC_URL}" ]]; then export STATIC_URL="empty_string"; fi
    if [[ -z "${API_URI}" ]]; then export API_URI="empty_string"; fi
    if [[ -z "${APP_MOUNT_URI}" ]]; then export APP_MOUNT_URI="empty_string"; fi

    replace_vars "STATIC_URL" "${STATIC_URL}" "/app/index.html" "/etc/nginx/app/index.html"
    replace_vars "STATIC_URL" "${STATIC_URL}" "/app/${dashboard_js_base_filepath}" "/etc/nginx/app/${dashboard_js_base_filepath}.1"
    replace_vars "API_URI" "${API_URI}" "/etc/nginx/app/${dashboard_js_base_filepath}.1" "/etc/nginx/app/${dashboard_js_base_filepath}.2"
    replace_vars "APP_MOUNT_URI" "${APP_MOUNT_URI}" "/etc/nginx/app/${dashboard_js_base_filepath}.2" "/etc/nginx/app/${dashboard_js_base_filepath}.3"

    cp "/etc/nginx/app/${dashboard_js_base_filepath}.3" "/etc/nginx/app/${dashboard_js_base_filepath}"

    rm "/etc/nginx/app/${dashboard_js_base_filepath}.1"
    rm "/etc/nginx/app/${dashboard_js_base_filepath}.2"
    rm "/etc/nginx/app/${dashboard_js_base_filepath}.3"

    cat /etc/nginx/app/index.html | grep -oP '.{100,100}src=.{100,150}'
    cat "/etc/nginx/app/${dashboard_js_base_filepath}" | grep -oP '.{100,100}a.oe=function(e).{100,150}'
    cat "/etc/nginx/app/${dashboard_js_base_filepath}" | grep -oP '.{100,100}apiUri.{100,150}'
    cat "/etc/nginx/app/${dashboard_js_base_filepath}" | grep -oP '.{100,100}onApiUriClick:function().{100,150}'
    cat "/etc/nginx/app/${dashboard_js_base_filepath}" | grep -oP '.{100,100}credentials:"include".{100,150}'
    cat "/etc/nginx/app/${dashboard_js_base_filepath}" | grep -oP '.{100,100}(Lu={}).{100,150}'
}

main
