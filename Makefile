GIT_SHA := $(shell git rev-parse --short HEAD)

build:
	docker build -t ghcr.io/mrzarquon/ecr-refresh:${GIT_SHA} .

push: 
	docker image tag ghcr.io/mrzarquon/ecr-refresh:${GIT_SHA} ghcr.io/mrzarquon/ecr-refresh:latest
	docker image push ghcr.io/mrzarquon/ecr-refresh:${GIT_SHA}
	docker image push ghcr.io/mrzarquon/ecr-refresh:latest

init:
	aws sso login
	aws eks update-kubeconfig --name ubuntu
	echo ${GHCR_PAT_PUSH} | docker login ghcr.io -u mrzarquon --password-stdin

debug: 
	docker run -i -t --rm \
	-v ${HOME}/.aws:/root/.aws \
	-v ${HOME}/.kube:/root/.kube \
	-e ECR_HELPER_DEBUG \
	-e ECR_HELPER_SERVER \
	-e GITPOD_REG_SECRET_NAME \
	--entrypoint=/bin/sh --name=ecr-helper ecr-helper:latest
