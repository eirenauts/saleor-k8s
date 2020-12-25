SHELL := /bin/bash

.PHONY: \
	init_yarn \
	init_go \
	init_shfmt \
	init_shellcheck \
	init_docker \
	init_docker_compose \
	init_hadolint \
	init_all \
	format_all \
	lint_all \
	build_saleor_core \
	push_saleor_core \
	get_image \
	get_image_version

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
	if [[ ! "$$(docker-compose version | awk NR==1)" =~ "${DOCKER_COMPOSE_VERSION}" ]]; then \
		./scripts/make.sh install_docker_compose "${DOCKER_COMPOSE_VERSION}"; \
	fi

init_hadolint:
	if [ -z "$$(command -v install_hadolint)" ]; then ./scripts/make.sh install_hadolint "${HADOLINT_VERSION}"; fi

init_all: \
	init_yarn \
	init_go \
	init_shfmt \
	init_shellcheck \
	init_docker \
	init_docker_compose \
	init_hadolint

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
	@./scripts/make.sh get_image saleor_core

get_image_version:
	@./scripts/make.sh get_image_version

build_saleor_core:
	./scripts/make.sh set_env_saleor_core
	./scripts/make.sh prepare_saleor_source "https://github.com/mirumee/saleor.git" "Core.Dockerfile"
	docker-compose build saleor_core
	docker run \
		--rm "$$(make -s get_image FILTER=saleor_core)" \
		/bin/bash -c 'echo "build ok"' || \
		(echo "docker image is broken"; exit 1;)
	docker image inspect \
		"$$(make -s get_image FILTER=saleor_core)"
	rm .env

build_saleor_core_dev:
	./scripts/make.sh set_env_saleor_core_dev
	./scripts/make.sh prepare_saleor_source "https://github.com/mirumee/saleor.git" "Core.Dev.Dockerfile"
	docker-compose build saleor_core_dev
	docker run \
		--rm "$$(make -s get_image FILTER=saleor_core_dev)" \
		/bin/bash -c 'echo "build ok"' || \
		(echo "docker image is broken"; exit 1;)
	docker image inspect \
		"$$(make -s get_image FILTER=saleor_core_dev)"
	rm .env

build_saleor_dashboard:
	./scripts/make.sh set_env_saleor_dashboard
	./scripts/make.sh prepare_saleor_source "https://github.com/mirumee/saleor-dashboard.git" "Dashboard.Dockerfile"
	docker-compose build saleor_dashboard
	docker run \
		--rm "$$(make -s get_image FILTER=saleor_dashboard)" \
		/bin/bash -c 'echo "build ok"' || \
		(echo "docker image is broken"; exit 1;)
	docker image inspect \
		"$$(make -s get_image FILTER=saleor_dashboard)"
	rm .env

build_saleor_storefront:
	./scripts/make.sh set_env_saleor_storefront
	./scripts/make.sh prepare_saleor_source "https://github.com/mirumee/saleor-storefront.git" "Dashboard.Dockerfile"
	docker-compose build saleor_storefront
	docker run \
		--rm "$$(make -s get_image FILTER=saleor_storefront)" \
		/bin/bash -c 'echo "build ok"' || \
		(echo "docker image is broken"; exit 1;)
	docker image inspect \
		"$$(make -s get_image FILTER=saleor_storefront)"
	rm .env

#push_saleor_core:
#	@if test -z "$(REGISTRY_TOKEN)"; then \
#		echo "env variable REGISTRY_TOKEN is required" && \
#		exit 1; \
#	fi;
#	docker tag \
#		"$$(make -s get_image FILTER=saleor_core)" \
#		"ghcr.io/eirenauts/saleor-core:$$(make -s get_image_version)"
#	docker tag \
#		"$$(make -s get_image FILTER=saleor_core)" \
#		"ghcr.io/eirenauts/saleor-core:latest"
#	echo "${REGISTRY_TOKEN}" | docker login ghcr.io -u eirenauts --password-stdin
#	docker push "ghcr.io/eirenauts/saleor-core:$$(make -s get_image_version)"
#	docker push "ghcr.io/eirenauts/saleor-core:latest"
#	docker logout ghcr.io
#	if [[ -e /home/vsts/.docker/config.json ]]; then rm /home/vsts/.docker/config.json; fi
