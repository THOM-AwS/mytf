
ifdef CI
	export AWS_DIR = ./init/aws
else
	export AWS_DIR = ~/.aws
endif

init: .env
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform init'
.PHONY: init

refresh: .env init
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform refresh'
.PHONY: refresh

plan: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform plan'
	docker-compose run --rm terraform-utils sh -c 'rm -rf .terraform/modules/'
.PHONY: plan

validate: .env
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform validate'
.PHONY: validate

output: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform output user_secret_access_key'
.PHONY: output

apply: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform apply'
	docker-compose run --rm terraform-utils sh -c 'rm -rf websites/.terraform/modules/'
	docker-compose run --rm terraform-utils sh -c 'rm -rf websites/secheader.py.zip'
.PHONY: apply

applyAuto: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform apply -auto-approve'
	docker-compose run --rm terraform-utils sh -c 'rm -rf websites/.terraform/modules/'
	docker-compose run --rm terraform-utils sh -c 'rm -rf websites/secheader.py.zip'
.PHONY: applyAuto

destroy: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform destroy -auto-approve'
.PHONY: destroy

import_resources: .env workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER};terraform import ...'

PHONY: plan

workspace: .env
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $(SUBFOLDER); terraform workspace select $(TERRAFORM_WORKSPACE) || terraform workspace new $(TERRAFORM_WORKSPACE)'
.PHONY: workspace

.env:
	touch .env
	docker-compose run --rm envvars validate
	docker-compose run --rm envvars envfile --overwrite
.PHONY: .env

recover_state:
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform state push errored.tfstate'
.PHONY: recover_state
