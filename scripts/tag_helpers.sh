#!/bin/bash

function is_valid_semver_tag() {
    local tag=$1
    local tag_regex='([0-9]+\.){2,2}(\*|[0-9]+)(\-.*){0,1}'

    if [[ -z "${tag}" ]]; then
        echo "A valid tag must be passed as the first argument" >>/dev/stderr
        return 0
    fi

    if [[ "${tag}" =~ $tag_regex ]]; then echo "true"; else echo "false"; fi
}

function get_current_chart_version() {
    local chart_dir=$1

    helm show chart "${chart_dir}/" |
        grep 'version' |
        tail -1 |
        cut -c 10-
}

function get_current_app_version() {
    local chart_dir=$1

    helm show chart "${chart_dir}/" |
        grep 'appVersion' |
        awk '{print $2}' |
        tr -d '"'
}

function version_chart() {
    local chart_tag=$1
    local app_tag=$2
    local chart_dir=$3

    if [[ "${chart_tag}" != "$(get_current_chart_version "${chart_dir}")" ]]; then
        sed -i "s|version: $(get_current_chart_version "${chart_dir}")|version: ${chart_tag}|" "${chart_dir}/Chart.yaml"
    fi

    if [[ -n "${app_tag}" ]] && [[ "${app_tag}" != "$(get_current_app_version "${chart_dir}")" ]]; then
        sed -i "s|appVersion: \"$(get_current_app_version "${chart_dir}")\"|appVersion: \"${app_tag}\"|" "${chart_dir}/Chart.yaml"
    fi
}

function apply_tag() {
    local tag=$1
    local app_version=$2

    if [[ "$(is_valid_semver_tag "${tag}")" != "true" ]]; then
        echo "A valid semver tag must be passed as the first argument" >>/dev/stderr
        return 0
    fi

    # Tag the chart
    echo "Versioning the chart with version ${tag} and appVersion ${app_version}"
    version_chart "${tag}" "${app_version}"

    # Tag the git repo
    echo "Tagging git repo with version ${tag}"
    git tag "${tag}"
}
