###these files can be overriden by devops pipeline
 ENV=dev
 ZONE=dev
 SUBSCRIPTION_ID=70981115-5fc9-4faa-a503-18e1541c0663
 CLIENT_ID=5a69a7fd-7b90-444e-aeea-4b5af19d24ae
 #VNET_NAME=vnet-vd-cust-dev-tools-1
 #VNET_RESOURCE_GROUP=shared
 SUBNET_PREFIX=10.0.0.0/23
 SENDGRIDAPIKEY=123
 EVENTHUB_PROCESSORSTORAGEACCESSKEY=123
 EVENTHUB_PROCESSORACCESSPOLICYKEY=123
###

 PROJECT=test
 TEAM=tools
 LOCATION=westeurope
 SA_RESOURCE_GROUP_NAME=martin
 STORAGE_ACCOUNT_NAME=sttftest
 TENANT_ID=a95532f4-6c46-4e23-b282-f2c591c0bef7
 CONTAINER_NAME=${STORAGE_ACCOUNT_NAME}c
 TFSTATE_FILE=${PROJECT}-$(ENV).tfstate
 SUBNET_ID=/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/martin/providers/Microsoft.Network/virtualNetworks/vnet-${PROJECT}-${ENV}/subnets/${PROJECT}-${ENV}
 REGISTRY_URL=crsimdevtools.azurecr.io
 REGISTRY_USER=crsimdevtools

#variables for tf state and import commands. Dont know if I need to declare them here, but it works
AZ_RESOURCE=xxx
RESOURCE=yyy

#these are exported as environment variables for terraform
.EXPORT_ALL_VARIABLES:
TF_LOG=error
ARM_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}
ARM_CLIENT_ID=${CLIENT_ID}
ARM_TENANT_ID=${TENANT_ID}
TF_VAR_ENVIRONMENT=${ENV}
TF_VAR_LOCATION=${LOCATION}
TF_VAR_TEAM=${TEAM}
TF_VAR_PROJECT=${PROJECT}
TF_VAR_SENDGRIDAPIKEY=${SENDGRIDAPIKEY}
TF_VAR_EVENTHUB_PROCESSORSTORAGEACCESSKEY=${EVENTHUB_PROCESSORSTORAGEACCESSKEY}
TF_VAR_EVENTHUB_PROCESSORACCESSPOLICYKEY=${EVENTHUB_PROCESSORACCESSPOLICYKEY}
#TF_VAR_VNET_NAME=${VNET_NAME}
#TF_VAR_VNET_RESOURCE_GROUP=${VNET_RESOURCE_GROUP}
TF_VAR_SUBNET_PREFIX=${SUBNET_PREFIX}

.PHONY: init plan apply destroy

tfinit:
ifndef ARM_CLIENT_SECRET
	$(error "ARM_CLIENT_SECRET is not set, please: export ARM_CLIENT_SECRET=somesecret")
endif
	cd terraform && rm -rf .terraform && terraform init -upgrade -backend-config="storage_account_name=${STORAGE_ACCOUNT_NAME}" -backend-config="container_name=${CONTAINER_NAME}" -backend-config="resource_group_name=${SA_RESOURCE_GROUP_NAME}"

tffmt:
	cd terraform && terraform fmt

tfvalid:
	cd terraform && terraform validate

tfplan: tfvalid tffmt
ifndef ARM_CLIENT_SECRET
	$(error "ARM_CLIENT_SECRET is not set, please: export ARM_CLIENT_SECRET=somesecret")
endif
	cd terraform && terraform get && terraform plan -no-color -out ./tfplan && terraform show -json tfplan > tfplan.json

tfapply:
ifndef ARM_CLIENT_SECRET
	$(error "ARM_CLIENT_SECRET is not set, please: export ARM_CLIENT_SECRET=somesecret")
endif
	cd terraform && terraform apply -parallelism=1 -auto-approve ./tfplan; rm ./tfplan

destroy:
ifndef ARM_CLIENT_SECRET
	$(error "ARM_CLIENT_SECRET is not set, please: export ARM_CLIENT_SECRET=somesecret")
endif
	# az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}
	# ./containerappenv_destroy.sh
	cd terraform && terraform destroy -auto-approve

check: valid
ifndef ARM_CLIENT_SECRET
	$(error "ARM_CLIENT_SECRET is not set, please: export ARM_CLIENT_SECRET=somesecret")
endif
	cd terraform && terraform get && terraform plan -no-color -detailed-exitcode

tfget:
ifndef ARM_CLIENT_SECRET
	$(error "ARM_CLIENT_SECRET is not set, please: export ARM_CLIENT_SECRET=somesecret")
endif
	cd terraform && rm -rf ./.terraform && terraform get

tfimport: 
ifndef ARM_CLIENT_SECRET
	$(error "ARM_CLIENT_SECRET is not set, please: export ARM_CLIENT_SECRET=somesecret")
endif
	cd terraform && terraform import ${RESOURCE} ${AZ_RESOURCE}

tfstatelist:
ifndef ARM_CLIENT_SECRET
	$(error "ARM_CLIENT_SECRET is not set, please: export ARM_CLIENT_SECRET=somesecret")
endif
	cd terraform && terraform state list

tfstateremove:
ifndef ARM_CLIENT_SECRET
	$(error "ARM_CLIENT_SECRET is not set, please: export ARM_CLIENT_SECRET=somesecret")
endif
	cd terraform && terraform state rm ${RESOURCE}

snyktest:
ifndef SNYK_TOKEN
	$(error "SNYK_TOKEN is not set, please: export SNYK_TOKEN=somesecret")
endif
	@snyk auth ${SNYK_TOKEN}
	snyk test --file=simployer.pim.customerdbupdater.sln --severity-threshold=high
	
dockerbuild:
ifndef REGISTRY_PASSWORD
	$(error "REGISTRY_PASSWORD is not set, please: export REGISTRY_PASSWORD=somesecret")
endif
	@docker login ${REGISTRY_URL} -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD}
	$(eval VERSION := $(shell git rev-parse --short HEAD))
	cd simployer.pim.customerdbupdater.worker && docker build -t ${REGISTRY_URL}/simployer.pim.customerdbupdater.worker:$(VERSION) -t ${REGISTRY_URL}/simployer.pim.customerdbupdater.worker:latest .
	docker push ${REGISTRY_URL}/simployer.pim.customerdbupdater.worker:$(VERSION)
	docker push ${REGISTRY_URL}/simployer.pim.customerdbupdater.worker:latest

# attach to docker container logs
dockerlogs:
	$(eval CONTAINER_ID := $(shell docker ps -q --filter ancestor=${REGISTRY_URL}/simployer.pim.customerdbupdater.worker))
	docker logs -f $(CONTAINER_ID)

dockerstop:
	$(eval CONTAINER_ID := $(shell docker ps -a -q --filter ancestor=${REGISTRY_URL}/simployer.pim.customerdbupdater.worker))
	docker stop $(CONTAINER_ID)
	
dockerrm:
	$(eval CONTAINER_ID := $(shell docker ps -a -q --filter ancestor=${REGISTRY_URL}/simployer.pim.customerdbupdater.worker))
	docker stop $(CONTAINER_ID)
	docker rm $(CONTAINER_ID)

deploy:
	ZONE=$$ZONE ENV=$$ENV REGISTRY_PASSWORD=$$REGISTRY_PASSWORD SECRETS=$$SECRETS terraform/containerapp.sh
