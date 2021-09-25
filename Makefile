
ifdef CI
	export AWS_DIR = ./init/aws
else
	export AWS_DIR = ~/.aws
endif

init: .env
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform init'
.PHONY: init

plan: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform plan'
	docker-compose run --rm terraform-utils sh -c 'rm -rf $${SUBFOLDER}/.terraform/modules'
.PHONY: plan

output: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform output user_secret_access_key'
	docker-compose run --rm terraform-utils sh -c 'rm -rf $${SUBFOLDER}/.terraform/modules'
.PHONY: output

apply: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform apply'
	docker-compose run --rm terraform-utils sh -c 'rm -rf $${SUBFOLDER}/.terraform/modules'
.PHONY: apply

applyAuto: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform apply -auto-approve'
	docker-compose run --rm terraform-utils sh -c 'rm -rf $${SUBFOLDER}/.terraform/modules'
.PHONY: applyAuto

destroy: .env init workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform destroy -auto-approve'
	docker-compose run --rm terraform-utils sh -c 'rm -rf $${SUBFOLDER}/.terraform/modules'
.PHONY: destroy

import_resources: .env workspace
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER};terraform import aws_iam_policy_attachment.awspolicy-attachment nscc-instance-role/arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore'

PHONY: plan

workspace: .env
	docker-compose run --rm envvars ensure --tags terraform
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform workspace new $(TERRAFORM_WORKSPACE); true' 
	docker-compose run --rm terraform-utils sh -c 'cd $${SUBFOLDER}; terraform workspace select $(TERRAFORM_WORKSPACE)' 
.PHONY: workspace

.env:
	touch .env
	docker-compose run --rm envvars validate
	docker-compose run --rm envvars envfile --overwrite
.PHONY: .env
