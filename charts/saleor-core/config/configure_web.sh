#!/usr/bin/env bash
# shellcheck disable=SC2120,SC2119

COLLECTSTATIC=${1}

function collectstatic() {
    python3 manage.py collectstatic --noinput
}

function main() {
    local collectstatic="${1:-COLLECTSTATIC}"

    if [[ "${collectstatic}" == "true" ]]; then
        collectstatic
    fi
}

main
