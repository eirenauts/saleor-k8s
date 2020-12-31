#!/usr/bin/env bash

function collectstatic() {
    python3 manage.py collectstatic --noinput
}

function main() {
    local collectstatic="${1}"

    if [[ "${collectstatic}" == "true" ]]; then
        collectstatic
    fi
}

main "${@}"
