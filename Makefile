.DEFAULT_GOAL := help

.PHONY: help
help: ## Print Makefile help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' ${MAKEFILE_LIST} | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'


SUDO               = $(shell which sudo)
IMAGE_NAME        ?= quay.io/danielhoherd/geekbench
CONTAINER_NAME    ?= geekbench
NO_CACHE          ?= false
ORG_PREFIX        ?= danielhoherd
GIT_ORIGIN         = $(shell git config --get remote.origin.url)
GIT_BRANCH         = $(shell git rev-parse --abbrev-ref HEAD)
GIT_SHA_SHORT      = $(shell if [ ! -z "`git status --porcelain`" ] ; then echo "DIRTY" ; else git rev-parse --short HEAD ; fi)
GIT_SHA_LONG       = $(shell if [ ! -z "`git status --porcelain`" ] ; then echo "DIRTY" ; else git rev-parse HEAD ; fi)
BUILD_TIME         = $(shell date '+%s')
RESTART           ?= always
# https://www.primatelabs.com/release/geekbench6/
GEEKBENCH_VERSION ?= 6.1.0-Linux
GEEKBENCH_PACKAGE ?= Geekbench-${GEEKBENCH_VERSION}.tar.gz


.PHONY: all
all: build

.PHONY: build
build: ## Build the Dockerfile found in PWD
	docker build --no-cache="${NO_CACHE}" \
		--build-arg GEEKBENCH_VERSION=${GEEKBENCH_VERSION} \
		--build-arg GEEKBENCH_PACKAGE=${GEEKBENCH_PACKAGE} \
		-t "${IMAGE_NAME}:latest" \
		-t "${IMAGE_NAME}:${GEEKBENCH_VERSION}" \
		-t "${IMAGE_NAME}:${GIT_BRANCH}-${GIT_SHA_SHORT}" \
		--label "com.geekbench.version=${GEEKBENCH_VERSION}" \
		--label "${ORG_PREFIX}.repo.origin=${GIT_ORIGIN}" \
		--label "${ORG_PREFIX}.repo.branch=${GIT_BRANCH}" \
		--label "${ORG_PREFIX}.repo.commit=${GIT_SHA_LONG}" \
		--label "${ORG_PREFIX}.build_time=${BUILD_TIME}" \
		.

.PHONY: install-hooks
install-hooks: ## Install git hooks
	pip3 install --user --upgrade pre-commit || \
	pip install --user --upgrade pre-commit
	pre-commit install -f --install-hooks

.PHONY: run
run: build ## Build and run the Dockerfile in pwd
	docker run \
		--rm \
		--name="${CONTAINER_NAME}" \
		"${IMAGE_NAME}"

.PHONY: debug
debug: build ## Build and debug the Dockerfile in pwd
	docker run \
		--interactive \
		--tty \
		--rm \
		--name="${IMAGE_NAME}-debug" \
		--net=host \
		--mount type=bind,src="${PWD}",dst="/data" \
		"${IMAGE_NAME}" bash

.PHONY: test
test: ## Test that the container functions
	docker run --rm -it "${IMAGE_NAME}" fping localhost

.PHONY: stop
stop: ## Delete deployed container
	-docker stop "${CONTAINER_NAME}"

.PHONY: delete
delete: rm
.PHONY: rm
rm: stop ## Delete deployed container
	-docker rm --force "${CONTAINER_NAME}"
	-docker rm --force "${CONTAINER_NAME}-debug"

.PHONY: logs
logs: ## View the last 30 minutes of log entries
	docker logs --since 30m "${CONTAINER_NAME}"

.PHONY: push
push: ## Push built container to docker hub
	docker push -a ${IMAGE_NAME}

.PHONY: check-package
check-package: ## Check that the package is available for download
	@echo GEEKBENCH_VERSION=${GEEKBENCH_VERSION}
	@echo GEEKBENCH_PACKAGE=${GEEKBENCH_PACKAGE}
	curl --max-filesize 1 -s -w "%{http_code}\n" -o /dev/null http://cdn.geekbench.com/${GEEKBENCH_PACKAGE} ; true

.PHONY: show-latest-version
show-latest-version: ## Show the latest version download URL
	curl -fsSL https://www.geekbench.com/download/linux | grep -m1 -o "https://cdn.geekbench[^\"']*"
