# Step by Step model deployment to AKS in a secure environment

## Main Challenges

You are in a secure environment, so, you need to: 
- Use a custom environment in your private container registry
- using a model with a scoring script

## How to

1. Connect to the jumpvm using Bastion
1. from the jumpvm, connect to azure.ml.com, connect to your private workspace
1. Attach AKS to AML : go to Compute/Kubernetes Clusters/New/Kubernetes give it a name, select the existing Kubernetes Cluster the terraform code created, and fill in "azureml" for the Kubernetes namespace.
1. Clone my repository to get the step by step notebook and default diabetes model : go to Compute/Compute instances/Select your instance/Terminal then launch `git clone git clone https://github.com/chboudry/aml-secure-terraform.git``
1. Open the Notebook called aks_example.ipynb and follow instructions there.