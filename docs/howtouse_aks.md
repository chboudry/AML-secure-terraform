# Step by Step model deployment to AKS in a secure environment

## Main Challenges

You are in a secure environment, so, you need to: 
- Use a custom environment in your private container registry
- using a model with a scoring script

## Environment

[Note about no-code-deployment](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-mlflow-models-online-endpoints?tabs=cli) : Azure Machine Learning performs dynamic installation of packages when deploying MLflow models with no-code deployment. As a consequence, deploying MLflow models to online endpoints with no-code deployment in a private network without egress connectivity is not supported by the moment.

This means we have to provide an environment and a scoring files for secured infrastructure.

All curated environment are part of mcr.microsoft.com and most customers do not want to allow public network trafic from/to their inference endpoint.

This means you have to create a custom environment that will be saved in your private container registry. You have 2 ways to do this :
- Define a custom environment within AML and let the image-builder cluster build it and save it in ACR for you. The cluster will require access to the source you are using.
- Use your own platform (a side VM ?) to create and push your docker image to the ACR, and then register it to AML.

### Build a custom environment within AML

Prerequisite : I am allowing my training subnet where my image-builder cluster sits to reach out to mcr.microsoft.com to use curated image as a base image to build my own and push it to my own ACR. (This is already implemented as part as the terraform code).

1. Connect to the jumpvm using Bastion
1. from the jumpvm, connect to azure.ml.com, connect to your private workspace
1. Attach AKS to AML : go to Compute/Kubernetes Clusters/New/Kubernetes give it a name, select the existing Kubernetes Cluster the terraform code created, and fill in "azureml" for the Kubernetes namespace.
1. 




https://github.com/Azure/AML-Kubernetes/blob/master/docs/simple-flow.md