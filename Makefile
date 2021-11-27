.PHONY: help 
help:
	@echo "-------------------------------------------------------------------"
	@echo "provision test infrastructure:"
	@echo ""
	@echo "test-infra-init              - initialize terraform for test infra"
	@echo "test-infra-deploy            - run terraform apply for test infra"
	@echo ""
	@echo "-------------------------------------------------------------------"
	@echo "test lambda functionality locally:"
	@echo ""
	@echo "sam-api                     - run locally lambda api integration"
	@echo "sam-test                    - test lambda api service"
	@echo ""
	@echo "-------------------------------------------------------------------"
	@echo "provision scheduler infrastructure:"
	@echo ""
	@echo "scheduler-init               - initialize terraform for scheduler"
	@echo "scheduler-deploy             - run terraform apply for scheduler"
	@echo ""
	@echo "-------------------------------------------------------------------"
	@echo "build cli docker image:"
	@echo ""
	@echo "cli-build                    - build docker image for scheduler cli"
	@echo "cli-test                     - create cli test container"
	@echo ""
	@echo "-------------------------------------------------------------------"
	@echo "test deployed scheduler:"
	@echo ""
	@echo "scheduler-test               - test scheduler deployed into aws"
	@echo ""
	@echo "-------------------------------------------------------------------"
	@echo "cleanup aws resources:"
	@echo ""
	@echo "test-infra-delete            - run terraform destroy for test infra"
	@echo "scheduler-delete             - run terraform destroy for scheduler"
	@echo


# -------------------------------------------------------------------
# provision test infrastructure:
# -------------------------------------------------------------------

.PHONY: test-infra-init
test-infra-init:
	terraform -chdir=./examples/test-infra init

.PHONY: test-infra-deploy
test-infra-deploy:
	terraform -chdir=./examples/test-infra apply --auto-approve


# -------------------------------------------------------------------
# test lambda functionality locally:
# -------------------------------------------------------------------

.PHONY: sam-api
sam-api:
	sam build -t ./app/template.yaml && sam local start-api --warm-containers EAGER

.PHONY: sam-test
sam-test:
	curl -XPOST "http://127.0.0.1:3000/api" -d '{"scheduler": { "action": "stop", "resources": { "asg": "true", "ec2": "true", "rds": "true" }, "tags": ["scheduled-dev", "scheduled-tst"] } }' 


# -------------------------------------------------------------------
# provision scheduler infrastructure:
# -------------------------------------------------------------------

.PHONY: scheduler-init
scheduler-init:
	terraform -chdir=./examples/scheduler init

.PHONY: scheduler-deploy
scheduler-deploy:
	terraform -chdir=./examples/scheduler apply --auto-approve


# -------------------------------------------------------------------
# build cli docker image:
# -------------------------------------------------------------------

.PHONY: cli-build
cli-build:
	cd cli && docker build -t aws-scheduler-cli . && cd ..

.PHONY: cli-test
cli-test:
	docker run --rm --name test -v ${HOME}/.aws:/root/.aws:ro -it aws-scheduler-cli


# -------------------------------------------------------------------
# test deployed scheduler:
# -------------------------------------------------------------------

.PHONY: scheduler-test
scheduler-test:
	@echo "\nstop ec2 instances and autoscaling groups for dev and tst envirs\n"
	@docker run --rm --name test -v ${HOME}/.aws:/root/.aws:ro aws-scheduler-cli \
		-n my-scheduler -a stop -e -g -t scheduled-dev scheduled-tst
	@read  -p "Press enter to continue"

	@echo "\nstart ec2 instances and autoscaling groups for dev and tst envirs\n"
	@docker run --rm --name test -v ${HOME}/.aws:/root/.aws:ro aws-scheduler-cli \
		-n my-scheduler -a start -e -g -t scheduled-dev scheduled-tst
	@read  -p "Press enter to continue"

	@echo "\ndisable scheduler for tst envir\n"
	@docker run --rm --name test -v ${HOME}/.aws:/root/.aws:ro aws-scheduler-cli \
		-n my-scheduler -a disable -e -g -r -t scheduled-tst
	@read  -p "Press enter to continue"

	@echo "\nstop ec2 instances and autoscaling groups for dev and tst envirs\n"
	@docker run --rm --name test -v ${HOME}/.aws:/root/.aws:ro aws-scheduler-cli \
		-n my-scheduler -a stop -e -g -t scheduled-dev scheduled-tst
	@read  -p "Press enter to continue"

	@echo "\nstart ec2 instances and autoscaling groups for dev and tst envirs\n"
	@docker run --rm --name test -v ${HOME}/.aws:/root/.aws:ro aws-scheduler-cli \
		-n my-scheduler -a start -e -g -t scheduled-dev scheduled-tst
	@read  -p "Press enter to continue"

	@echo "\nenable scheduler for all envirs\n"
	@docker run --rm --name test -v ${HOME}/.aws:/root/.aws:ro aws-scheduler-cli \
		-n my-scheduler -a enable -e -g -r -t scheduled-dev scheduled-tst scheduled-prd
	@read  -p "Press enter to continue"

	@echo "\nshutdown all environments\n"
	@docker run --rm --name test -v ${HOME}/.aws:/root/.aws:ro aws-scheduler-cli \
		-n my-scheduler -a stop -e -g -r -t scheduled-dev scheduled-tst scheduled-prd


# -------------------------------------------------------------------
# cleanup aws resources:
# -------------------------------------------------------------------

.PHONY: scheduler-delete
scheduler-delete:
	terraform -chdir=./examples/scheduler destroy --auto-approve

.PHONY: test-infra-delete
test-infra-delete:
	terraform -chdir=./examples/test-infra destroy --auto-approve
	

# -------------------------------------------------------------------
# other helpers:
# -------------------------------------------------------------------

.PHONY: test-lambda-invoke 
test-lambda-invoke:
	@aws lambda invoke --function-name my-scheduler --payload file://./app/events/disable-tst.json --cli-binary-format raw-in-base64-out /dev/stdout
