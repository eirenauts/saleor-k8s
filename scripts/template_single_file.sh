#!/bin/bash
# shellcheck disable=SC2086

set -o pipefail

function validate_args() {
    local filename="${1}"
    local chart_dir="${2}"
    local values_filepath="${3}"
    local release_name="${4}"
    local namespace="${5}"
    local set_additional_values="${6}"

    if [[ -z "${filename}" ]]; then
        echo "filename is required" >>/dev/stderr
        return
    fi

    if [[ -z "${chart_dir}" ]]; then
        echo "chart_dir is required" >>/dev/stderr
        return
    fi

    if [[ -z "${values_filepath}" ]]; then
        echo "values_filepath is required" >>/dev/stderr
        return
    fi

    if [[ -z "${release_name}" ]]; then
        echo "release_name is required" >>/dev/stderr
        return
    fi

    if [[ -z "${namespace}" ]]; then
        echo "namespace is required" >>/dev/stderr
        return
    fi

    if [[ -z "${set_additional_values}" ]]; then
        echo "set_additional_values is required" >>/dev/stderr
        return
    fi
}

# Example usage:
# template_single_file backup-job.yaml charts/saleor-core values/saleor-core.yaml saleor-platform
function template_single_file() {
    local filename="${1}"
    local chart_dir="${2}"
    local values_filepath="${3}"
    local release_name="${4}"
    local namespace="${5}"
    local set_additional_values="${6}"

    helm template \
        --release-name "${release_name}" \
        --namespace "${namespace}" \
        ${set_additional_values} \
        "${chart_dir}" \
        --values "${values_filepath}" |
        awk "/${filename}/,/---/" |
        awk 'NR>2 {print last} {last=$0}'
}

function main() {
    local filename="${1}"
    local chart_dir="${2}"
    local values_filepath="${3}"
    local release_name="${4}"
    local namespace="${5}"
    local set_additional_values="${6}"

    validate_args \
        "${filename}" \
        "${chart_dir}" \
        "${values_filepath}" \
        "${release_name}" \
        "${namespace}" \
        "${set_additional_values}"

    template_single_file \
        "${filename}" \
        "${chart_dir}" \
        "${values_filepath}" \
        "${release_name}" \
        "${namespace}" \
        "${set_additional_values}"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
    main "${@}"
fi
