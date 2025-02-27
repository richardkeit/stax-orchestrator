SHELL = /bin/bash
SHELLFLAGS = -ex

ARTIFACT_BUCKET_NAME     := $(shell aws ssm get-parameter --name /orchestrator/stax/artifact/bucket/name --query Parameter.Value --output text --with-decryption)
GIT_HASH                 ?= $(shell git rev-parse --short HEAD)
GIT_BRANCH               ?= $(shell git rev-parse --abbrev-ref HEAD)

help: ## Get help about Makefile commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install-dev-dependencies: ## Install project dependencies (including dev dependencies) using pipenv
	pipenv install --dev

install-dependencies: ## Install project dependencies using pipenv
	pipenv install

shell: ## Spawn a shell in the current virtual environment
	pipenv shell

lint-statemachine: ## Lint step function definition files using statelint
	pipenv run statelint --ignore=URI statemachines/*

lint-yaml: ## Run yamllint against all .yml files in the current directory
	pipenv run yamllint *.yml

lint: format ## Lint python files with black, pylint and check imports with isort
	pipenv run isort --check-only --diff functions src tests
	pipenv run black --check -l 119 --diff functions src tests
	pipenv run pylint --fail-under=10.0 functions src

format: ## Format python files with black and fix imports with isort
	pipenv run isort functions src tests
	pipenv run black functions src tests -l 119

test: ## Run python unit tests
	export AWS_XRAY_SDK_ENABLED=False && pipenv run python -m pytest -vvvv \
		--cov-config=.coveragerc \
		--cov-report xml:coverage-reports/coverage-report.xml \
		--cov-fail-under=100 \
		--cov-report term-missing \
		--cov=. \
		tests/

build-StaxLibLayer: clean install-dependencies ## Build lambda layer with dependencies and src files
	pipenv run pip freeze > requirements.txt
	mkdir -p "$(ARTIFACTS_DIR)/python"
	mkdir -p "$(ARTIFACTS_DIR)/python/src"
	cp ./src/*.py "$(ARTIFACTS_DIR)/python/src"
	pipenv run python -m pip install \
		--isolated \
		--disable-pip-version-check \
		-Ur requirements.txt -t $(ARTIFACTS_DIR)/python

build-app: ## Use sam cli to build the app
	sam build

invoke-create-workload-lambda-locally: ## Invoke CreateWorkloadLambda running in a docker container locally
	sam local invoke CreateWorkloadLambda -e events/create_workload_innovation.json

clean: ## Cleanup local artifacts
	rm -rf requirements.txt template.packaged.yml .aws-sam

deploy-stax-orchestrator: clean build-app package-app ## Deploy Stax Orchestrator to AWS
	$(info [+] Deploying Stax Orchestrator...)
	@sam deploy --no-fail-on-empty-changeset \
		--stack-name orchestrator-stax \
		--capabilities CAPABILITY_NAMED_IAM \
		--tags "orchestrator-stax:branch=$(GIT_BRANCH)" "orchestrator-stax:version=$(GIT_HASH)" \
		--template-file template.packaged.yml \
		--s3-bucket $(ARTIFACT_BUCKET_NAME)
	@make clean

package-app: ## Package and upload application artifacts to the stax deployment bucket
	sam package --output-template-file template.packaged.yml --s3-bucket $(ARTIFACT_BUCKET_NAME)

publish-app: build-app package-app ## Publish Stax Orchestrator Application to Serverless Application Repository
	sam publish --template template.packaged.yml --region $(AWS_REGION) --semantic-version $(TAGGED_VERSION)

.PHONY: clean build-app build-StaxLibLayer deploy-stax-orchestrator invoke-create-workload-lambda-locally format lint shell install-dependencies install-dev-dependencies help package-app publish-app test lint-yaml lint-statemachine
