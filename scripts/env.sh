#!/bin/bash

function set_env_saleor_core() {
    if [[ -e .env ]]; then
        rm .env &&
            touch .env
    fi

    {
        echo "SHORT_SHA=$(get_short_sha)"
        echo "VERSION=$(get_image_version https://github.com/mirumee/saleor.git)"
    } >>.env
}

function set_env_saleor_core_dev() {
    if [[ -e .env ]]; then
        rm .env &&
            touch .env
    fi

    {
        echo "SHORT_SHA=$(get_short_sha)"
        echo "VERSION=dev-$(get_image_version https://github.com/mirumee/saleor.git)"
    } >>.env
}

function set_env_saleor_dashboard() {
    if [[ -e .env ]]; then
        rm .env &&
            touch .env
    fi

    {
        echo "SHORT_SHA=$(get_short_sha)"
        echo "VERSION=$(get_image_version https://github.com/mirumee/saleor-dashboard.git)"
    } >>.env
}

function set_env_saleor_storefront() {
    if [[ -e .env ]]; then
        rm .env &&
            touch .env
    fi

    {
        echo "SHORT_SHA=$(get_short_sha)"
        echo "VERSION=$(get_image_version https://github.com/mirumee/saleor-storefront.git)"
    } >>.env
}
