SHELL := /bin/bash

.PHONY: \
	init_yarn \
	init_go \
	init_shfmt \
	init_shellcheck \
	init_docker \
	init_docker_compose \
	init_hadolint \
	init_helm \
	init_chart_releaser \
	init_all \
	format_all \
	lint_all \
	prepare_saleor_sources \
	build_saleor_core \
	build_saleor_core_dev \
	build_saleor_dashboard \
	build_saleor_storefront \
	push_saleor_core \
	push_saleor_core_dev \
	push_saleor_dashboard \
	push_saleor_storefront \
	get_image \
	get_image_version \
	push_image \
	push_updated_charts


## Dependency installation targets

init_yarn:
	if [ -z "$$(command -v yarn)" ]; then ./scripts/make.sh install_yarn; fi
	if [ -z "$$(command -v ./node_modules/.bin/prettier)" ]; then ./scripts/make.sh install_yarn; fi
	if [ -z "$$(command -v ./node_modules/.bin/markdownlint)" ]; then ./scripts/make.sh install_yarn; fi

init_go:
	if [[ -z "$$(command -v go)" ]]; then ./scripts/make.sh install_golang "${GO_LANG_VERSION}"; fi

init_shfmt:
	if [ -z "$$(command -v shfmt)" ]; then ./scripts/make.sh install_shfmt "${SHFMT_VERSION}"; fi

init_shellcheck:
	if [ -z "$$(command -v shellcheck)" ]; then ./scripts/make.sh install_shellcheck "${SHELLCHECK_VERSION}"; fi

init_docker:
	if [ -z "$$(command -v docker)" ]; then ./scripts/make.sh install_docker "${DOCKER_VERSION}"; fi
	if [[ ! "$$(docker version | awk NR==2)" =~ "${DOCKER_VERSION}" ]]; then \
		./scripts/make.sh install_docker "${DOCKER_VERSION}"; \
	fi

init_docker_compose:
	if [ -z "$$(command -v docker)" ]; then ./scripts/make.sh install_docker_compose "${DOCKER_COMPOSE_VERSION}"; fi
	if [[ -z "$$(command -v docker-compose)" ]]; then ./scripts/make.sh install_docker_compose "${DOCKER_COMPOSE_VERSION}"; fi

init_helm:
	if [ -z "$$(command -v helm)" ]; then ./scripts/make.sh install_helm_client "${HELM_VERSION}"; fi

init_hadolint:
	if [ -z "$$(command -v install_hadolint)" ]; then ./scripts/make.sh install_hadolint "${HADOLINT_VERSION}"; fi

init_chart_releaser:
	if [ -z "$$(command -v cr)" ]; then ./scripts/make.sh install_helm_chart_releaser "${CHART_RELEASER_VERSION}"; fi

init_all: \
	init_yarn \
	init_go \
	init_shfmt \
	init_shellcheck \
	init_docker \
	init_docker_compose \
	init_helm \
	init_hadolint \
	init_chart_releaser

## Code consistency/quality targets

format_all: init_all
	./scripts/make.sh format_yaml
	./scripts/make.sh format_shell
	./scripts/make.sh format_markdown

lint_all: init_all
	./scripts/make.sh lint_yaml
	./scripts/make.sh lint_shell
	./scripts/make.sh lint_markdown
	./scripts/make.sh lint_dockerfiles

get_image:
	@if test -z "$(FILTER)"; then \
		echo "env variable FILTER is required" && \
		exit 1; \
	fi;
	@./scripts/make.sh get_image "${FILTER}"
	unset FILTER

get_image_version:
	@if test -z "$(SALEOR_REPO)"; then \
		echo "env variable SALEOR_REPO is required" && \
		exit 1; \
	fi;
	@./scripts/make.sh get_image_version "${SALEOR_REPO}"
	unset SALEOR_REPO

push_image:
	@if test -z "$(IMAGE_VERSION)"; then \
		echo "env variable IMAGE_VERSION is required" && \
		exit 1; \
	fi;
	@if test -z "$(DOCKER_REPO)"; then \
		echo "env variable DOCKER_REPO is required" && \
		exit 1; \
	fi;
	@./scripts/make.sh push_image "${IMAGE_VERSION}" "${DOCKER_REPO}" "${FORCE_PUSH}"
	unset IMAGE_VERSION
	unset DOCKER_REPO

prepare_saleor_sources:
	./scripts/make.sh prepare_saleor_source \
		"https://github.com/mirumee/saleor.git" \
		"Core.Dockerfile" && \
	./scripts/make.sh prepare_saleor_source \
		"https://github.com/mirumee/saleor.git" \
		"Core.Dev.Dockerfile" && \
	./scripts/make.sh prepare_saleor_source \
		"https://github.com/mirumee/saleor-dashboard.git" \
		"Dashboard.Dockerfile" && \
	./scripts/make.sh prepare_saleor_source \
		"https://github.com/mirumee/saleor-storefront.git" \
		"Storefront.Dockerfile"

build_saleor_core: prepare_saleor_sources
	./scripts/make.sh set_env_saleor_core
	docker-compose build saleor_core
	docker image ls
	make -s get_image FILTER=saleor_core
	docker run \
		--rm "$$(make -s get_image FILTER=saleor_core)" \
		/bin/bash -c 'echo "build ok"' || \
		(echo "docker image is broken"; exit 1;)
	docker image inspect \
		"$$(make -s get_image FILTER=saleor_core)"
	rm .env

build_saleor_core_dev: prepare_saleor_sources
	./scripts/make.sh set_env_saleor_core_dev
	docker-compose build saleor_core_dev
	docker image ls
	make -s get_image FILTER=saleor_core_dev
	docker run \
		--rm "$$(make -s get_image FILTER=saleor_core_dev)" \
		/bin/bash -c 'echo "build ok"' || \
		(echo "docker image is broken"; exit 1;)
	docker image inspect \
		"$$(make -s get_image FILTER=saleor_core_dev)"
	rm .env

build_saleor_dashboard: prepare_saleor_sources
	./scripts/make.sh set_env_saleor_dashboard
	docker-compose build saleor_dashboard
	docker image ls
	make -s get_image FILTER=saleor_dashboard
	docker run \
		--rm "$$(make -s get_image FILTER=saleor_dashboard)" \
		/bin/bash -c 'echo "build ok"' || \
		(echo "docker image is broken"; exit 1;)
	docker image inspect \
		"$$(make -s get_image FILTER=saleor_dashboard)"
	rm .env

build_saleor_storefront: prepare_saleor_sources
	./scripts/make.sh set_env_saleor_storefront
	docker-compose build saleor_storefront
	docker image ls
	make -s get_image FILTER=saleor_storefront
	docker run \
		--rm "$$(make -s get_image FILTER=saleor_storefront)" \
		/bin/bash -c 'echo "build ok"' || \
		(echo "docker image is broken"; exit 1;)
	docker image inspect \
		"$$(make -s get_image FILTER=saleor_storefront)"
	rm .env

push_saleor_core:
	@if test -z "$(REGISTRY_TOKEN)"; then \
		echo "env variable REGISTRY_TOKEN is required" && \
		exit 1; \
	fi;
	docker tag \
		"$$(make -s get_image FILTER=saleor_core)" \
		"ghcr.io/eirenauts/saleor-core:$$(make -s get_image_version SALEOR_REPO=https://github.com/mirumee/saleor.git)"
	docker tag \
		"$$(make -s get_image FILTER=saleor_core)" \
		"ghcr.io/eirenauts/saleor-core:latest"
	echo "${REGISTRY_TOKEN}" | docker login ghcr.io -u eirenauts --password-stdin
	make -s push_image \
		IMAGE_VERSION="$$(make -s get_image_version SALEOR_REPO=https://github.com/mirumee/saleor.git)" \
		DOCKER_REPO=saleor-core \
		FORCE_PUSH="${FORCE_PUSH_IMAGES}"
	docker logout ghcr.io
	if [[ -e /home/vsts/.docker/config.json ]]; then rm /home/vsts/.docker/config.json; fi

push_saleor_core_dev:
	@if test -z "$(REGISTRY_TOKEN)"; then \
		echo "env variable REGISTRY_TOKEN is required" && \
		exit 1; \
	fi;
	docker tag \
		"$$(make -s get_image FILTER=saleor_core_dev)" \
		"ghcr.io/eirenauts/saleor-core:dev-$$(make -s get_image_version SALEOR_REPO=https://github.com/mirumee/saleor.git)"
	docker tag \
		"$$(make -s get_image FILTER=saleor_core_dev)" \
		"ghcr.io/eirenauts/saleor-core:dev-latest"
	echo "${REGISTRY_TOKEN}" | docker login ghcr.io -u eirenauts --password-stdin
	make -s push_image \
		IMAGE_VERSION="dev-$$(make -s get_image_version SALEOR_REPO=https://github.com/mirumee/saleor.git)" \
		DOCKER_REPO=saleor-core \
		FORCE_PUSH="${FORCE_PUSH_IMAGES}"
	docker logout ghcr.io
	if [[ -e /home/vsts/.docker/config.json ]]; then rm /home/vsts/.docker/config.json; fi

push_saleor_dashboard:
	@if test -z "$(REGISTRY_TOKEN)"; then \
		echo "env variable REGISTRY_TOKEN is required" && \
		exit 1; \
	fi;
	docker tag \
		"$$(make -s get_image FILTER=saleor_dashboard)" \
		"ghcr.io/eirenauts/saleor-dashboard:$$(make -s get_image_version SALEOR_REPO=https://github.com/mirumee/saleor-dashboard.git)"
	docker tag \
		"$$(make -s get_image FILTER=saleor_dashboard)" \
		"ghcr.io/eirenauts/saleor-dashboard:latest"
	echo "${REGISTRY_TOKEN}" | docker login ghcr.io -u eirenauts --password-stdin
	make -s push_image \
		IMAGE_VERSION="$$(make -s get_image_version SALEOR_REPO=https://github.com/mirumee/saleor-dashboard.git)" \
		DOCKER_REPO=saleor-dashboard \
		FORCE_PUSH="${FORCE_PUSH_IMAGES}"
	docker logout ghcr.io
	if [[ -e /home/vsts/.docker/config.json ]]; then rm /home/vsts/.docker/config.json; fi

push_saleor_storefront:
	@if test -z "$(REGISTRY_TOKEN)"; then \
		echo "env variable REGISTRY_TOKEN is required" && \
		exit 1; \
	fi;
	docker tag \
		"$$(make -s get_image FILTER=saleor_storefront)" \
		"ghcr.io/eirenauts/saleor-storefront:$$(make -s get_image_version SALEOR_REPO=https://github.com/mirumee/saleor-storefront.git)"
	docker tag \
		"$$(make -s get_image FILTER=saleor_storefront)" \
		"ghcr.io/eirenauts/saleor-storefront:latest"
	echo "${REGISTRY_TOKEN}" | docker login ghcr.io -u eirenauts --password-stdin
	make -s push_image \
		IMAGE_VERSION="$$(make -s get_image_version SALEOR_REPO=https://github.com/mirumee/saleor-storefront.git)" \
		DOCKER_REPO=saleor-storefront \
		FORCE_PUSH="${FORCE_PUSH_IMAGES}"
	docker logout ghcr.io
	if [[ -e /home/vsts/.docker/config.json ]]; then rm /home/vsts/.docker/config.json; fi

push_updated_charts:
	@if test -z "$(CR_TOKEN)"; then \
		echo "env variable CR_TOKEN is required" && \
		exit 1; \
	fi;
	./scripts/make.sh package_newly_versioned_charts "${CR_TOKEN}"
