# .EXPORT_ALL_VARIABLES:
# ARM_SUBSCRIPTION_ID=70981115-5fc9-4faa-a503-18e1541c0663
# ARM_CLIENT_ID=5a69a7fd-7b90-444e-aeea-4b5af19d24ae
# ARM_TENANT_ID=a95532f4-6c46-4e23-b282-f2c591c0bef7
# TF_VAR_LOCATION=West Europe
# TF_VAR_ENVIRONMENT=dev


GIT_SHA:=$(shell git rev-parse --short HEAD)
IMAGE_TAG?=${GIT_SHA}
RG_NAME?=rg-sodafactoryapi-dev
APP_NAME?=app-sodafactoryapi-dev
SA_ENV=dev

buildapi: ## Build the docker image
	docker build -t ${APP_NAME}:${IMAGE_TAG} .

run: ## Run the docker image
	docker run -it --rm -p 8080:8080 ${APP_NAME}:${IMAGE_TAG}

push: ## Push the docker image to the registry
	docker tag ${APP_NAME}:${IMAGE_TAG} ${APP_NAME}:${IMAGE_TAG}
	docker push ${APP_NAME}:${IMAGE_TAG}

deploy: ## Deploy the docker image to the registry
	az acr build --registry ${APP_NAME} --image ${APP_NAME}:${IMAGE_TAG} .

clean: ## Clean the docker image
	docker rmi ${APP_NAME}:${IMAGE_TAG}

up: docker-compose-build ## Docker-Compose Up
	docker-compose up -d

down:
	docker-compose down

k6-build:
	cd k6 && npm install && npm start

k6-run: k6-build
	cd k6 && k6 run dist/Mainfunction.js --http-debug=full 

install-ef-core: ## Install ef core
	dotnet tool update --global dotnet-ef