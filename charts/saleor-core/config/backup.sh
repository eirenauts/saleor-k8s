#!/usr/bin/env bash

POSTGRESQL_PASSWORD=${1}
POSTGRESQL_HOST=${2}
POSTGRESQL_PORT=${3}
POSTGRESQL_USER=${4}
POSTGRESQL_DATABASE=${5}

function init() {

    # List snapshots and only initialize repo if not already initialized
    # restic snapshots --host restic
    restic init --host restic
}

function execute_pg_dump() {
    local postgresql_password=${1:-POSTGRESQL_PASSWORD}
    local postgresql_host=${2:-POSTGRESQL_HOST}
    local postgresql_port=${3:-POSTGRESQL_PORT}
    local postgresql_user=${4:-POSTGRESQL_USER}
    local postgresql_database=${5:-POSTGRESQL_DATABASE}

    echo "Work in progress" &&
        PGPASSWORD="${postgresql_password}" \
            pg_dump \
            --host="${postgresql_host}" \
            --port="${postgresql_port}" \
            --username="${postgresql_user}" \
            --dbname="${postgresql_database}" \
            --no-password >/saleor-core-postgresql.dump &&
        echo "Finished pg_dump successfully" ||
        echo "Finished pg_dump unsuccessfuly"
}

function execute_database_backup() {
    # TODO
    # restic --no-cache --host restic
    # restic --verbose --host restic
    echo "TODO"
}

function main() {
    echo "Work in progress"

    execute_pg_dump \
        "${POSTGRESQL_PASSWORD}" \
        "${POSTGRESQL_HOST}" \
        "${POSTGRESQL_PORT}" \
        "${POSTGRESQL_USER}" \
        "${POSTGRESQL_DATABASE}"

    execute_database_backup
}

main
