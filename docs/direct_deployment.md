
## Use the SAM CLI to build and test the application locally

Build the Lambda functions in your application with the `sam build --use-container` command used within the following `make` command,

```
stax-orchestrator$ make build-app
```

The SAM CLI installs dependencies defined in `requirements.txt`, creates a deployment package, and saves it in the `.aws-sam/build` folder. The `make` command `make prepare-lambda-layer-dir` builds the lambda layer directory using the requirements file.

Once you have built the app locally, try running `make run-create-workload-lambda-locally` to test running the workload create lambda locally.

## Deploy Stax Orchestrator

The Serverless Application Model Command Line Interface (SAM CLI) is an extension of the AWS CLI that adds functionality for building and testing Lambda applications. It uses Docker to run your functions in an Amazon Linux environment that matches Lambda.

To use the Stax Orchestrator Application, you need the following tools:

* SAM CLI - [Install the SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
* [Python 3.9 installed](https://www.python.org/downloads/)
* Docker - [Install Docker community edition](https://hub.docker.com/search/?type=edition&offering=community)
* [Make](https://www.gnu.org/software/make/manual/make.html)
* Workload Deployment Bucket (See Readme's section #Stax Deployment Bucket)

To build and deploy your application for the first time, run the following in your shell:

```bash
make deploy-stax-orchestrator
```

Sam will build the source of your application and deploy Stax Orchestrator to AWS.

## Fetch, tail, and filter Lambda function logs

To simplify troubleshooting, SAM CLI has a command called `sam logs`. `sam logs` lets you fetch logs generated by your deployed Lambda function from the command line. In addition to printing the logs on the terminal, this command has several nifty features to help you quickly find the bug.

`NOTE`: This command works for all AWS Lambda functions; not just the ones you deploy using SAM.

```bash
stax-orchestrator$ sam logs -n CreateWorkloadLambda --stack-name orchestrator-stax --tail
```

You can find more information and examples about filtering Lambda function logs in the [SAM CLI Documentation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-logging.html).
