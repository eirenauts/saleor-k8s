#!/usr/bin/env bash

POSTGRESQL_PASSWORD=${1}
POSTGRESQL_HOST=${2}
POSTGRESQL_PORT=${3}
POSTGRESQL_USER=${4}
POSTGRESQL_DATABASE=${5}
VATLAYER_API_KEY=${6}
BRAINTREE_PRIVATE_KEY=${7}
BRAINTREE_PUBLIC_KEY=${8}
BRAINTREE_SANDBOX_MODE=${9}
BRAINTREE_MERCHANT_ID=${10}
BRAINTREE_CURRENCIES=${11}
BRAINTREE_REQUIRE_3D_SECURE=${12}

function execute_plugin_sql_query() {
    local postgresql_password="${1}"
    local postgresql_host="${2}"
    local postgresql_port="${3}"
    local postgresql_user="${4}"
    local postgresql_database="${5}"
    local jsonb="${6}"
    local identifier="${7}"

    if [[ -z "${jsonb}" ]]; then
        echo "Variable jsonb is missing" >>/dev/stderr
    fi

    if [[ -z "${identifier}" ]]; then
        echo "Variable identifier is missing" >>/dev/stderr
    fi

    echo "Starting activation of the ${identifier} plugin" &&
        {
            PGPASSWORD="${postgresql_password}" \
                psql \
                --host="${postgresql_host}" \
                --port="${postgresql_port}" \
                --username="${postgresql_user}" \
                --dbname="${postgresql_database}" \
                --no-password \
                --csv \
                --quiet <<EOF
INSERT INTO "public"."plugins_pluginconfiguration"
  ("id", "name", "description", "active", "configuration", "identifier")
VALUES
  ((SELECT nextval(pg_get_serial_sequence('plugins_pluginconfiguration', 'id'))), '', '', true, '${jsonb}', '${identifier}')
ON CONFLICT (identifier)
DO
UPDATE SET configuration='${jsonb}';
EOF
        } &&
        echo "Finished activation of the ${identifier} plugin successfully" ||
        echo "Finished activation of the ${identifier}  plugin unsuccessfuly"
}

function activate_vatlayer() {
    local postgresql_password="${1}"
    local postgresql_host="${2}"
    local postgresql_port="${3}"
    local postgresql_user="${4}"
    local postgresql_database="${5}"
    local vatlayer_api_key="${6}"
    local jsonb
    local identifier

    jsonb='[{"name": "Access key", "type": "Password", "label": "Access key", "value": "'"${vatlayer_api_key}"'", "help_text": "Required to authenticate to Vatlayer API."}]'
    identifier='mirumee.taxes.vatlayer'

    execute_plugin_sql_query \
        "${postgresql_password}" \
        "${postgresql_host}" \
        "${postgresql_port}" \
        "${postgresql_user}" \
        "${postgresql_database}" \
        "${jsonb}" \
        "${identifier}"
}

function activate_braintree() {
    local postgresql_password="${1}"
    local postgresql_host="${2}"
    local postgresql_port="${3}"
    local postgresql_user="${4}"
    local postgresql_database="${5}"
    local braintree_private_key="${6}"
    local braintree_public_key="${7}"
    local braintree_sandbox_mode="${8}"
    local braintree_merchant_id="${9}"
    local braintree_currencies="${10}"
    local braintree_require_3d_secure="${11}"
    local jsonb
    local identifier

    if [[ -z "${braintree_currencies}" ]]; then
        braintree_currencies="AUD,BRL,CAD,CHF,CNY,CZK,DKK,EUR,GBP,HKD,HUF,ILS,INR,ISK,KRW,NOK,NZD,PLN,RUB,SEK,SGD,TRY,TWD,USD,UYU,VND,ZAR,"
    fi

    jsonb='[{"name": "Public API key", "type": "Secret", "label": "Public API key", "value": "'"${braintree_public_key}"'", "help_text": "Provide Braintree public API key."}, {"name": "Secret API key", "type": "Secret", "label": "Secret API key", "value": "'"${braintree_private_key}"'", "help_text": "Provide Braintree secret API key."}, {"name": "Use sandbox", "type": "Boolean", "label": "Use sandbox", "value": '${braintree_sandbox_mode}', "help_text": "Determines if Saleor should use Braintree sandbox API."}, {"name": "Merchant ID", "type": "Secret", "label": "Merchant ID", "value": "'"${braintree_merchant_id}"'", "help_text": "Provide Braintree merchant ID."}, {"name": "Store customers card", "type": "Boolean", "label": "Store customers card", "value": false, "help_text": "Determines if Saleor should store cards on payments in Braintree customer."}, {"name": "Automatic payment capture", "type": "Boolean", "label": "Automatic payment capture", "value": true, "help_text": "Determines if Saleor should automaticaly capture payments."}, {"name": "Require 3D secure", "type": "Boolean", "label": "Require 3D secure", "value": '${braintree_require_3d_secure}', "help_text": "Determines if Saleor should enforce 3D secure during payment."}, {"name": "Supported currencies", "type": "String", "label": "Supported currencies", "'"${braintree_currencies}"'": "", "help_text": "Determines currencies supported by gateway. Please enter currency codes separated by a comma."}]'
    identifier='mirumee.payments.braintree'

    execute_plugin_sql_query \
        "${postgresql_password}" \
        "${postgresql_host}" \
        "${postgresql_port}" \
        "${postgresql_user}" \
        "${postgresql_database}" \
        "${jsonb}" \
        "${identifier}"
}

function main() {

    if [[ -n "${VATLAYER_API_KEY}" ]]; then
        activate_vatlayer \
            "${POSTGRESQL_PASSWORD}" \
            "${POSTGRESQL_HOST}" \
            "${POSTGRESQL_PORT}" \
            "${POSTGRESQL_USER}" \
            "${POSTGRESQL_DATABASE}" \
            "${VATLAYER_API_KEY}"
    fi

    if [[ -n "${BRAINTREE_PRIVATE_KEY}" ]]; then
        activate_braintree \
            "${POSTGRESQL_PASSWORD}" \
            "${POSTGRESQL_HOST}" \
            "${POSTGRESQL_PORT}" \
            "${POSTGRESQL_USER}" \
            "${POSTGRESQL_DATABASE}" \
            "${BRAINTREE_PRIVATE_KEY}" \
            "${BRAINTREE_PUBLIC_KEY}" \
            "${BRAINTREE_SANDBOX_MODE}" \
            "${BRAINTREE_MERCHANT_ID}" \
            "${BRAINTREE_CURRENCIES}" \
            "${BRAINTREE_REQUIRE_3D_SECURE}"
    fi
}

main
