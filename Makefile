build: 
	docker build -t ecr-helper .

aws-init:
	aws sso login
	aws eks update-kubeconfig --name ubuntu