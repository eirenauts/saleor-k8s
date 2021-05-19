#!/bin/bash
# shellcheck shell=bash disable=SC1090,SC1091,SC2015

function install_yarn() {
    sudo apt update -y -qq && sudo apt install -y -qq curl gnupg &&
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - &&
        echo "deb https://dl.yarnpkg.com/debian/ stable main" |
        sudo tee /etc/apt/sources.list.d/yarn.list &&
        sudo apt update -y -qq && sudo apt install -y -qq yarn &&
        yarn --version &&
        yarn install --frozen-lockfile
}

function install_golang() {
    local release=$1

    if [[ -z "${release}" ]]; then
        release=1.15.6
    fi

    if [ -z "$(command -v wget)" ]; then
        sudo apt-get install -y -qq wget
    fi

    wget --quiet "https://dl.google.com/go/go${release}.linux-amd64.tar.gz"

    if [[ -d /usr/local/go ]]; then
        sudo rm -R /usr/local/go
    fi

    sudo tar -C /usr/local -xzf go${release}.linux-amd64.tar.gz &&
        echo "export PATH=$PATH:/usr/local/go/bin" >>"${HOME}/.bash_profile" &&
        echo "export GOPATH=${HOME}/go" >>"${HOME}/.bash_profile" &&
        echo "export GOROOT=/usr/local/go" >>"${HOME}/.bash_profile" &&
        source "${HOME}/.bash_profile" &&
        go version
}

function install_shfmt() {
    local release=$1
    local goos
    local goarch

    goarch="$(go env GOARCH)"
    goos="$(go env GOOS)"

    if [[ -z "${release}" ]]; then
        release=3.2.1
    fi

    if [ -z "$(command -v git)" ]; then
        sudo apt-get install -y -qq git
    fi

    GOPATH=${GOPATH:-${HOME}/go} &&
        GOOS="${goos}" GOARCH="${goarch}" \
            GO111MODULE=on go get "mvdan.cc/sh/v3/cmd/shfmt@v${release}" &&
        sudo mv "${GOPATH}/bin/shfmt" /usr/local/bin/shfmt &&
        shfmt --version
}

function install_shellcheck() {
    local release=$1
    local shellcheck_url
    shellcheck_url=https://github.com/koalaman/shellcheck/releases/download

    if [[ -z "${release}" ]]; then
        release=0.7.1
    fi

    if [ -z "$(command -v wget)" ]; then
        sudo apt-get install -y -qq wget
    fi

    wget --quiet "${shellcheck_url}/v${release}/shellcheck-v${release}.linux.x86_64.tar.xz" &&
        tar \
            -C ./ \
            -xf shellcheck-v${release}.linux.x86_64.tar.xz &&
        sudo mv \
            ./shellcheck-v${release}/shellcheck \
            /usr/local/bin/shellcheck &&
        sudo chmod +x /usr/local/bin/shellcheck &&
        sudo rm -R ./shellcheck-v${release} &&
        shellcheck --version
}

function install_docker() {
    local release="${1}"

    if [[ -z "${release}" ]]; then
        release=20.10.0
    fi

    sudo apt update -y -qq &&
        sudo apt install -y -qq apt-transport-https ca-certificates curl software-properties-common &&
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" &&
        sudo apt update -y -qq &&
        docker_version="$(sudo apt-cache madison docker-ce | grep "${release}" | head -1 | awk '{print $3}')" &&
        sudo apt-get install -y -qq --allow-downgrades docker-ce="${docker_version}" &&
        if [[ -n "${USER}" ]]; then
            sudo usermod -aG docker "${USER}"
        fi
}

function install_docker_compose() {
    local release="${1}"

    if [[ -z "${release}" ]]; then
        release=1.27.4
    fi

    sudo curl \
        -L "https://github.com/docker/compose/releases/download/${release}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose &&
        sudo chmod +x /usr/local/bin/docker-compose &&
        docker-compose --version
}

function install_hadolint() {
    local release="${1}"
    local download_url
    download_url=https://github.com/hadolint/hadolint/releases/download

    if [[ -z "${release}" ]]; then
        release=1.19.0
    fi

    wget --quiet "${download_url}/v${release}/hadolint-Linux-x86_64" &&
        chmod +x hadolint-Linux-x86_64 &&
        sudo mv hadolint-Linux-x86_64 /usr/local/bin/hadolint &&
        hadolint --version
}

function install_helm_chart_releaser() {
    local release="${1}"
    local download_url
    download_url=https://github.com/helm/chart-releaser/releases/download

    if [[ -z "${release}" ]]; then
        release=1.1.1
    fi

    mkdir -p ./downloads/cr

    wget --quiet "${download_url}/v${release}/chart-releaser_${release}_linux_amd64.tar.gz" &&
        tar -C ./downloads/cr -xvzf chart-releaser_${release}_linux_amd64.tar.gz &&
        sudo chmod +x ./downloads/cr/cr &&
        sudo mv ./downloads/cr/cr /usr/local/bin/cr &&
        cr version
}

function format_yaml() {
    yarn prettier --write ./**/*.y*ml
}

function format_markdown() {
    yarn prettier --write ./**/*.md
}

function format_shell() {
    find . \
        -type f \
        -name "*.sh" \
        ! -path './saleor_core/**' \
        ! -path './saleor_core_dev/**' \
        ! -path './saleor_storefront/**' \
        ! -path './saleor_dashboard/**' \
        -exec shfmt -l -w {} +
    shfmt -l -w ./charts/saleor-core/config/backup.sh
}

function lint_yaml() {
    yarn prettier --check ./**/*.y*ml &&
        yamllint --strict ./
}

function lint_shell() {
    find . \
        -type f \
        -name "*.sh" \
        ! -path './saleor_core/**' \
        ! -path './saleor_core_dev/**' \
        ! -path './saleor_storefront/**' \
        ! -path './saleor_dashboard/**' \
        -exec shellcheck -x {} +
    shellcheck -x ./charts/saleor-core/config/backup.sh
}

function lint_markdown() {
    yarn markdownlint ./
}

function lint_dockerfiles() {
    hadolint \
        --config .hadolint.yaml \
        images/Core.Dockerfile &&
        hadolint \
            --config .hadolint.yaml \
            --ignore DL3009 \
            images/Core.Dev.Dockerfile &&
        hadolint \
            --config .hadolint.yaml \
            images/Dashboard.Dockerfile &&
        hadolint \
            --config .hadolint.yaml \
            images/Storefront.Dockerfile
}

function get_image() {
    local filter="${1}"

    docker image ls --filter reference="*_${filter}" | awk 'NR==2{print $1}'
}

function get_short_sha() {
    git rev-parse --short --quiet HEAD || echo "unknown"
}

function get_branch_from_ci() {
    if [[ -n "${SYSTEM_PULLREQUEST_SOURCEBRANCH}" ]]; then
        sed --regexp-extended 's|refs/heads/||g' <<<"${SYSTEM_PULLREQUEST_SOURCEBRANCH}"
    elif [[ -n "${BUILD_SOURCEBRANCH}" ]]; then
        sed --regexp-extended 's|refs/heads/||g' <<<"${BUILD_SOURCEBRANCH}"
    elif [[ -n "${CI_COMMIT_REF_NAME}" ]]; then
        sed --regexp-extended 's|refs/heads/||g' <<<"${CI_COMMIT_REF_NAME}"
    fi
}

function get_git_branch() {
    if [[ -z "$(get_branch_from_ci)" ]]; then
        git branch --show-current
    else
        get_branch_from_ci
    fi
}

function get_redacted_git_branch() {
    sed --regexp-extended 's|\W|-|g' <<<"$(get_git_branch)"
}

function get_short_sha() {
    git rev-parse --short --quiet HEAD
}

function get_image_version() {
    local saleor_repo="${1}"
    local branch

    if [[ -z "${saleor_repo}" ]]; then
        echo "Variable saleor_repo is required" >>/dev/stderr
        return
    fi

    branch="$(get_redacted_git_branch)"
    short_sha="$(get_short_sha)"
    required_version="$(get_required_app_version "${saleor_repo}")"

    if [[ "${branch}" != "master" ]]; then
        echo "${branch}-${short_sha}"
    else
        echo "${required_version}"
    fi
}

function determine_chart_dir() {
    local saleor_repo="${1}"
    local chart_dir

    if [[ -z "${saleor_repo}" ]]; then
        echo "Variable saleor_repo is required" >>/dev/stderr
        return
    fi

    if [[ "${saleor_repo}" == "https://github.com/mirumee/saleor.git" ]]; then
        chart_dir="charts/saleor-core"
    fi

    if [[ "${saleor_repo}" == "https://github.com/mirumee/saleor-dashboard.git" ]]; then
        chart_dir="charts/saleor-dashboard"
    fi

    if [[ "${saleor_repo}" == "https://github.com/mirumee/saleor-storefront.git" ]]; then
        chart_dir="charts/saleor-storefront"
    fi

    if [[ -z "${chart_dir}" ]]; then
        echo "Variable saleor_repo is set incorrectly" >>/dev/stderr
        return
    fi

    echo "${chart_dir}"
}

function get_required_app_version() {
    local saleor_repo="${1}"

    if [[ -z "${saleor_repo}" ]]; then
        echo "Variable saleor_repo is required" >>/dev/stderr
        return
    fi

    chart_dir="$(determine_chart_dir "${saleor_repo}")"

    helm show chart "${chart_dir}/" |
        grep 'appVersion' |
        awk '{print $2}' |
        tr -d '"'
}

function get_working_directory() {
    local dockerfile="${1}"

    if [[ -z "${dockerfile}" ]]; then
        echo "Variable dockerfile is required" >>/dev/stderr
        return
    fi

    echo "saleor_$(echo "${dockerfile}" |
        awk -F.Dockerfile '{print $1}' |
        tr '[:upper:]' '[:lower:]' |
        tr '.' '_')"
}

function prepare_saleor_source() {
    local saleor_repo=${1:-https://github.com/mirumee/saleor.git}
    local dockerfile=${2:-Core.Dockerfile}
    local saleor_release
    local working_dir

    working_dir="$(get_working_directory "${dockerfile}")"

    if [[ -d "./${working_dir}" ]]; then
        echo "Removing ./${working_dir}"
        rm -rf "./${working_dir}"
    fi

    saleor_release="$(get_required_app_version "${saleor_repo}")"

    echo "Checking out version ${saleor_release} of ${saleor_repo}"
    git clone "${saleor_repo}" "./${working_dir}" &&
        cd "./${working_dir}" &&
        git checkout "${saleor_release}" &&
        if [[ "${dockerfile}" == "Core.Dockerfile" ]] || [[ "${dockerfile}" == "Core.Dev.Dockerfile" ]]; then
            echo "Copying gunicorn config file into saleor repo" &&
                cp ../images/config/gunicorn_conf.py ./saleor/gunicorn_conf.py
            echo "Removing unecessary static files" &&
                rm ./saleor/static/populatedb_data.json &&
                rm -rf ./saleor/static/placeholders
        fi &&
        cp "../images/${dockerfile}" ./Dockerfile &&
        cat Dockerfile
}

function docker_push() {
    local docker_repo="${1}"
    local image_version="${2}"

    docker push "ghcr.io/eirenauts/${docker_repo}:${image_version}" &&
        if [[ "${image_version}" == *"dev-"* ]]; then
            docker push "ghcr.io/eirenauts/${docker_repo}:dev-latest"
        else
            docker push "ghcr.io/eirenauts/${docker_repo}:latest"
        fi
}

function push_image() {
    local image_version="${1}"
    local docker_repo="${2}"
    local force_push="${3}"

    if [[ -z "${image_version}" ]]; then
        echo "Variable image_version is required" >>/dev/stderr
        return
    fi

    if [[ -z "${docker_repo}" ]]; then
        echo "Variable docker_repo is required" >>/dev/stderr
        return
    fi

    if [[ -n "${force_push}" ]]; then
        echo "Force pushing images"
        docker_push "${docker_repo}" "${image_version}"
    else
        docker manifest inspect "ghcr.io/eirenauts/${docker_repo}:${image_version}" >/dev/null 2>&1 &&
            echo "Image already exists, skipping push" ||
            docker_push "${docker_repo}" "${image_version}"
    fi
}
