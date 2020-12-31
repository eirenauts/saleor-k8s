#!/bin/bash
# shellcheck shell=bash disable=SC1090
# shellcheck shell=bash disable=SC2015

function install_kubectl() {
    local release="${1}"
    local download_url

    download_url=https://storage.googleapis.com/kubernetes-release/release

    if [[ -z "${release}" ]]; then
        release=1.20.0
    fi

    wget --quiet "${download_url}/v${release}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl
}

function install_helm_client() {
    local release=$1

    if [[ -z "${release}" ]]; then
        release=3.4.1
    fi

    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh --version "v${release}"
}

install_k8s_venv_deps() {
    local ansible_version="${1}"
    local jmespath_version="${2}"
    local openshift_version="${3}"
    local pip_version="${4}"

    pip3 install pip=="${pip_version}" &&
        pip3 install ansible=="${ansible_version}" &&
        pip3 install jmespath=="${jmespath_version}" &&
        pip3 install openshift=="${openshift_version}" &&
        ansible-galaxy collection install community.kubernetes
}

function activate_venv() {
    python3 -m venv ~/.venv/k8s-venv &&
        source ~/.venv/k8s-venv/bin/activate
}

function deactivate_venv() {
    deactivate
}

function install_k8s_venv() {
    local ansible_version="${1}"
    local jmespath_version="${2}"
    local openshift_version="${3}"
    local pip_version="${4}"

    if [[ -z "${ansible_version}" ]]; then
        ansible_version=2.10.4
    fi

    if [[ -z "${jmespath_version}" ]]; then
        jmespath_version=0.10.0
    fi

    if [[ -z "${openshift_version}" ]]; then
        openshift_version=0.11.2
    fi

    if [[ -z "${pip_version}" ]]; then
        pip_version=20.3.3
    fi

    python3 -m venv --help &&
        (activate_venv &&
            install_k8s_venv_deps \
                "${ansible_version}" \
                "${jmespath_version}" \
                "${openshift_version}" \
                "${pip_version}") ||
        (sudo apt install python3-venv -y -q &&
            activate_venv &&
            install_k8s_venv_deps \
                "${ansible_version}" \
                "${jmespath_version}" \
                "${openshift_version}" \
                "${pip_version}")
}
