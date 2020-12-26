#!/bin/bash
# @description
#
#     Example Usage
#
#      * Set saleor-core chart at 0.1.0 as the chart version and 2.11.1 as the appVersion
#
#       version_chart "0.1.0" "2.11.1" "charts/saleor-core"
#
#     Example Usage
#
#      * Set versions for all the charts
#
#       version_chart "0.1.0" "2.11.1" "charts/saleor-core"
#       version_chart "0.1.0" "2.11.1" "charts/saleor-dashboard"
#       version_chart "0.1.0" "2.11.1" "charts/saleor-storefront"
#       version_chart "0.1.0" "2.11.1" "charts/saleor-platform"
#
#     Note: appVersion in saleor-platform is inherently ignored

function get_current_chart_version() {
    local chart_dir="${1}"

    if [[ -z "${chart_dir}" ]]; then
        echo "Variable chart_dir is required" >>/dev/stderr
        return
    fi

    helm show chart "${chart_dir}/" |
        grep 'version' |
        tail -1 |
        cut -c 10-
}

function get_previous_chart_version() {
    local chart_dir="${1}"
    local previous_release
    local previous_checkout_point

    previous_release=$(git tag --list | tail -2 | awk 'NR==1')

    if [[ -z "${chart_dir}" ]]; then
        echo "Variable chart_dir is required" >>/dev/stderr
        return
    fi

    if [[ -z "${previous_release}" ]]; then
        previous_checkout_point=HEAD~1
    else
        previous_checkout_point="${previous_release}"
    fi

    git checkout -q "${previous_checkout_point}"

    previous_chart_version=$(
        helm show chart "${chart_dir}/" |
            grep 'version' |
            tail -1 |
            cut -c 10-
    )

    git checkout -q -

    echo "${previous_chart_version}"
}

function get_current_app_version() {
    local chart_dir="${1}"

    helm show chart "${chart_dir}/" |
        grep 'appVersion' |
        awk '{print $2}' |
        tr -d '"'
}

function version_chart() {
    local chart_tag="${1}"
    local app_tag=$2
    local chart_dir=$3

    if [[ "${chart_tag}" != "$(get_current_chart_version "${chart_dir}")" ]]; then
        sed -i "s|version: $(get_current_chart_version "${chart_dir}")|version: ${chart_tag}|" "${chart_dir}/Chart.yaml"
    fi

    if [[ -n "${app_tag}" ]] && [[ "${app_tag}" != "$(get_current_app_version "${chart_dir}")" ]]; then
        sed -i "s|appVersion: \"$(get_current_app_version "${chart_dir}")\"|appVersion: \"${app_tag}\"|" "${chart_dir}/Chart.yaml"
    fi
}

package_chart() {
    local chart_dir="${1}"

    echo "Packaging chart ${chart}..."
    cr package \
        --config .cr.yaml \
        "${chart_dir}"
}

upload_packaged() {
    local token="${1}"

    if [[ -z "${token}" ]]; then
        echo "Variable token is required" >>/dev/stderr
        return
    fi

    if [[ -d .packaged ]]; then
        echo 'Uploading charts...'
        cr upload \
            --token "${token}" \
            --config .cr.yaml
    else
        echo "No charts have been packaged, skipping upload"
    fi
}

reindex() {
    local token="${1}"

    if [[ -z "${token}" ]]; then
        echo "Variable token is required" >>/dev/stderr
        return
    fi

    if [[ -d .packaged ]]; then
        echo 'Updating repo index...'
        cr upload \
            --token "${token}" \
            --config .cr.yaml
    else
        echo "No charts have been packaged, skipping index update"
    fi
}

package_newly_versioned_charts() {
    local newly_versioned_charts
    newly_versioned_charts=()

    for chart in ./charts/*; do
        if [[ -d "${chart}" ]]; then
            current_chart_version="$(get_current_chart_version "${chart}")"
            previous_chart_version="$(get_previous_chart_version "${chart}")"
            if [[ "${current_chart_version}" != "${previous_chart_version}" ]]; then
                newly_versioned_charts+=("${chart}")
            fi
        fi
    done

    if [[ ${#newly_versioned_charts[@]} -eq 0 ]]; then
        echo "No chart version has changed since last release. No action taken."
        rm -rf .packaged
    else
        rm -rf .packaged && mkdir .packaged
        for chart in "${newly_versioned_charts[@]}"; do
            echo "Chart ${chart} has a new chart version"
            if [[ -d "${chart}" ]]; then
                helm dep update "${chart}" &&
                    package_chart "${chart}"
            else
                echo "Chart ${chart} no longer exists, skipping it..."
            fi
        done
    fi
}

push_charts() {
    local token="${1}"

    if [[ -z "${token}" ]]; then
        echo "Variable token is required" >>/dev/stderr
        return
    fi

    upload_packaged "${token}"
    reindex "${token}"
}
