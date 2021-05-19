#!/usr/bin/env bash
# shellcheck disable=SC2086,SC2153

set -eo pipefail

export AWS_ACCESS_KEY_ID="${RESTIC_S3_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${RESTIC_S3_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${RESTIC_S3_REGION}"

function try_restic_initialization() {
    local restic_global_args=${1}
    local restic_host=${2}

    if [[ -z "${restic_host}" ]]; then
        echo "Variable restic_host is required, exiting"
        exit 1
    fi

    restic snapshots ${restic_global_args} --host ${restic_host} ||
        (
            echo "Initializing the restic repository" &&
                restic init ${restic_global_args}
        ) &&
        (
            echo "The restic repository has already been initialized"
        )
}

function init() {
    if [[ -z "${RESTIC_REPOSITORY}" ]]; then
        echo "Environment variable RESTIC_REPOSITORY not set, exiting"
        exit 1
    fi

    if [[ -z "${RESTIC_S3_REGION}" ]]; then
        echo "Environment variable RESTIC_S3_REGION not set, exiting"
        exit 1
    fi

    if [[ -z "${RESTIC_PASSWORD}" ]]; then
        echo "Environment variable RESTIC_PASSWORD not set, exiting"
        exit 1
    fi

    if [[ -z "${RESTIC_S3_ACCESS_KEY_ID}" ]]; then
        echo "Environment variable RESTIC_S3_ACCESS_KEY_ID not set, exiting"
        exit 1
    fi

    if [[ -z "${RESTIC_S3_SECRET_ACCESS_KEY}" ]]; then
        echo "Environment variable RESTIC_S3_SECRET_ACCESS_KEY not set, exiting"
        exit 1
    fi

    if [[ -z "${RESTIC_HOST}" ]]; then
        echo "Environment variable RESTIC_HOST not set, exiting"
        exit 1
    fi

    if [[ -z "${RESTIC_GLOBAL_ARGS}" ]]; then
        try_restic_initialization --host "${RESTIC_HOST}"
    else
        try_restic_initialization "${RESTIC_GLOBAL_ARGS}" --host "${RESTIC_HOST}"
    fi
}

function execute_pg_dump() {
    local postgresql_password=${1}
    local postgresql_host=${2}
    local postgresql_port=${3}
    local postgresql_user=${4}
    local postgresql_database=${5}
    local postgresql_additional_args=${6}

    if [[ ! -d /home/saleor/backups/database ]]; then
        mkdir -p /home/saleor/backups/database
    fi

    echo "Dumping postgresql database with the following arguments:"
    echo "host: ${postgresql_host}"
    echo "port: ${postgresql_port}"
    echo "username: ${postgresql_user}"
    echo "dbname: ${postgresql_database}"

    if [[ -z "${postgresql_additional_args}" ]]; then
        PGPASSWORD="${postgresql_password}" \
            pg_dump \
            --verbose \
            --host="${postgresql_host}" \
            --port="${postgresql_port}" \
            --username="${postgresql_user}" \
            --dbname="${postgresql_database}" \
            --no-password >/home/saleor/backups/database/saleor-core-postgresql.dump
    else
        echo "additional arguments: ${postgresql_additional_args}"
        PGPASSWORD="${postgresql_password}" \
            pg_dump \
            ${postgresql_additional_args} \
            --host="${postgresql_host}" \
            --port="${postgresql_port}" \
            --username="${postgresql_user}" \
            --dbname="${postgresql_database}" \
            --no-password >/home/saleor/backups/database/saleor-core-postgresql.dump
    fi &&
        echo "Finished pg_dump successfully" ||
        echo "Finished pg_dump unsuccessfuly"
}

function restic_save_db() {
    local restic_global_args=${1}
    local restic_host=${2}

    restic backup \
        ${restic_global_args} \
        --host "${restic_host}-db" \
        /home/saleor/backups/database/saleor-core-postgresql.dump &&
        echo "Saved media backup via restic tool successfully" ||
        echo "Saved media backup via restic tool unsuccessfully"
}

function restic_save_media() {
    local restic_global_args=${1}
    local restic_host=${2}

    restic backup \
        ${restic_global_args} \
        --host "${restic_host}-media" \
        /app/media &&
        echo "Saved media backup via restic tool successfully" ||
        echo "Saved media backup via restic tool unsuccessfully"
}

function display_snapshots() {
    restic snapshots --verbose --no-cache
}

function main() {
    local do_postgresql_backup=${1}
    local postgresql_password=${2}
    local postgresql_host=${3}
    local postgresql_port=${4}
    local postgresql_user=${5}
    local postgresql_database=${6}
    local postgresql_additional_args=${7}
    local do_media_backup=${8}
    local restic_global_args=${9}
    local restic_host=${10}

    init

    if [[ "${do_postgresql_backup}" == "true" ]]; then
        echo "Postgresql backup is to be executed"

        execute_pg_dump \
            "${postgresql_password}" \
            "${postgresql_host}" \
            "${postgresql_port}" \
            "${postgresql_user}" \
            "${postgresql_database}" \
            "${postgresql_additional_args}"
    fi
    if [[ "${do_media_backup}" == "true" ]]; then
        echo "Saving media files using restic"

        restic_save_media \
            "${restic_global_args}" \
            "${restic_host}"
    fi
    if [[ "${do_postgresql_backup}" == "true" ]]; then
        echo "Saving postgresql backup using restic"

        restic_save_db \
            "${restic_global_args}" \
            "${restic_host}"
    fi

    display_snapshots
}

main "${@}"
