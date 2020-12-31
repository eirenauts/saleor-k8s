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

function package_chart() {
    local chart_dir="${1}"

    echo "Packaging chart ${chart_dir}..."
    cr package \
        "${chart_dir}" \
        --config .cr.yaml
}

function upload_packaged() {
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

function reindex() {
    local token="${1}"

    if [[ -z "${token}" ]]; then
        echo "Variable token is required" >>/dev/stderr
        return
    fi

    if [[ -d .packaged ]]; then
        echo 'Updating repo index...'
        cr index \
            --token "${token}" \
            --config .cr.yaml
    else
        echo "No charts have been packaged, skipping index update"
    fi
}

function add_required_subcharts() {
    helm repo add saleor-k8s https://eirenauts.github.io/saleor-k8s
    helm repo add kvaps https://kvaps.github.io/charts
    helm repo add bitnami https://charts.bitnami.com/bitnami
    sleep 15s
    helm repo update
}

function package_newly_versioned_charts() {
    local token="${1}"
    local newly_versioned_charts

    if [[ -z "${token}" ]]; then
        echo "Variable token is required" >>/dev/stderr
        return
    fi

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
            if [[ -d "${chart}" ]] && [[ "${chart}" != "./charts/saleor-platform" ]]; then
                package_chart "${chart}"
            fi
        done

        upload_packaged "${token}"
        sleep 8s
        reindex "${token}"
        sleep 8s

        for chart in "${newly_versioned_charts[@]}"; do
            if [[ -d "${chart}" ]] && [[ "${chart}" == "./charts/saleor-platform" ]]; then
                rm -rf .packaged
                if [[ -d ./charts/saleor-platform/charts ]]; then
                    rm -rf ./charts/saleor-platform/charts
                fi
                if [[ -d ./charts/saleor-platform/tmpcharts ]]; then
                    rm -rf ./charts/saleor-platform/tmpcharts
                fi
                add_required_subcharts
                helm dep update "${chart}"
                package_chart "${chart}"
            fi
        done

        upload_packaged "${token}"
        sleep 8s
        reindex "${token}"
        sleep 8s
    fi
}
