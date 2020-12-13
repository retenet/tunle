ifndef ARCH
	ARCH=amd64
endif

PROJECT_NAME = $(notdir $(shell pwd))

DOCKER_IMAGE ?= retenet/$(PROJECT_NAME)
DOCKER_TAG = $(ARCH)


# Get the latest commit.
GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))

# Find out if the working directory is clean
GIT_NOT_CLEAN_CHECK = $(shell git status --porcelain)

# If we're releasing to Docker Hub, and we're going to mark it with the latest tag, it should exactly match a version release
ifeq ($(MAKECMDGOALS),release)

# Don't push to Docker Hub if this isn't a clean repo
ifneq (x$(GIT_NOT_CLEAN_CHECK), x)
$(error echo You are trying to release a build based on a dirty repo)
endif

endif


all: help

build:
	@docker build . --no-cache \
		--build-arg ARCH=$(DOCKER_TAG) \
		--build-arg VERSION=$(CODE_VERSION) \
		--build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg VCS_REF=$(GIT_COMMIT) \
		-t $(DOCKER_IMAGE):$(DOCKER_TAG)

release: build
	@docker manifest create $(DOCKER_IMAGE):latest \
		$(DOCKER_IMAGE):amd64 \
		$(DOCKER_IMAGE):i386 \
		$(DOCKER_IMAGE):arm64v8 \
		$(DOCKER_IMAGE):arm32v7 \
		$(DOCKER_IMAGE):arm32v6
	@docker manifest push -p $(DOCKER_IMAGE):latest
	@docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

test: build
	@docker run -d --rm \
		-h $(PROJECT_NAME) \
		--name $(PROJECT_NAME) \
		--env-file $(pwd)/configs/test.conf
		--cap-drop all \
		--cap-add SETGID \
		--cap-add SETUID \
		--cap-add MKNOD \
		--cap-add NET_ADMIN \
		--cap-add NET_RAW \
		$(DOCKER_IMAGE):$(DOCKER_TAG) bash >/dev/null 2>&1 \
		|| echo "Container already running. 'make stop' to kill."
	@docker logs -f tunle

stop:
	@docker kill $(PROJECT_NAME) >/dev/null 2>&1 || true
	@docker rm $(PROJECT_NAME) >/dev/null 2>&1

help:
	@echo ''
	@echo 'Usage: make [TARGET] [OPTIONS]'
	@echo 'Targts:'
	@echo -e '\tbuild	build docker image for $(DOCKER_TAG)'
	@echo -e '\tlogs	show running image logs'
	@echo -e '\trelease	push image to $(DOCKER_IMAGE)'
	@echo -e '\trun 	run the image'
	@echo -e '\tstop	stop the running image'
	@echo -e '\ttest	launch the image with shell'
	@echo 'OPTIONS:'
	@echo -e '\tARCH=:	make ARCH=arm64v8'
	@echo 'ARCHITECTURES:'
	@echo -e '\tamd64 	[default]'
	@echo -e '\twindows-amd64'
	@echo -e '\tarm32v6'
	@echo -e '\tarm32v7'
	@echo -e '\tarm64v8'
	@echo -e '\tarm32v5'
	@echo -e '\tppc64le'
	@echo -e '\ts390x'
	@echo -e '\tmips64le'
	@echo -e '\ti386'

.PHONY: help build logs push run stop
