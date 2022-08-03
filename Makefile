build: 
	docker build -t ecr-helper .

aws-init:
	aws sso login
	aws eks update-kubeconfig --name ubuntu

debug: 
	docker run -i -t --rm \
	-v ${HOME}/.aws:/root/.aws \
	-v ${HOME}/.kube:/root/.kube \
	-e ECR_HELPER_DEBUG \
	-e ECR_HELPER_SERVER \
	-e GITPOD_REG_SECRET_NAME \
	--entrypoint=/bin/sh --name=ecr-helper ecr-helper:latest
