# AKS

## Motivation

AKS should be used for AML for people that already have one.
Otherwise the recommended choice is Managed Endpoint.

## Governance and security consideration for production 

- AKS SHOULD have its own spoke
- ml extension SHOULD'NT have a public IP

## A note about ml extension

AzureML extension has pretty powerful configuration possibilities.

You can review [all its settings here](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-kubernetes-extension?tabs=deploy-extension-with-cli#review-azureml-extension-configuration-settings).

Here is [official terraform syntax for the extension](https://learn.microsoft.com/en-us/azure/templates/microsoft.kubernetesconfiguration/2022-03-01/extensions?pivots=deployment-language-terraform). 

Here is [one example to deploy it in ARM](https://github.com/Azure/AML-Kubernetes/blob/master/files/deployextension.json).

If you are not sure how to configure your settings, I would suggest deploying through cli and then reverse-engineering it using : 
`az k8s-extension list --cluster-name CLUSTER_NAME --resource-group RG_NAME --cluster-type managedClusters`


## Terrafom code explained 

We need to :
1. Create an AKS cluster
1. Manage internals

In Terraform, it is not recommended to do both of those in the same module.
This is why you have 2 submodule within the module spoke_aks.

Module aks_cluster will :
1. create the cluster
1. create the diagnostics settings
1. add the ml extension

Module kubernetes_config, running afterwards will:
1. Create an nginx_ingress namespace
1. Put a controller within it
1. Create an ingress in the azureml namespace to redirect /aml/ traffic to azureml-fe

## How to improve

- While kubernetes configuration was done in terraform, ultimately this should be done out of it using Gitops methodology
- Add TLS & certificate
- Add RBAC authentication
- Make the API private

## Interesting Links

Kubernetes management through terraform:
- https://github.com/hashicorp/terraform-provider-kubernetes/tree/main/_examples/aks
- https://github.com/HoussemDellai/terraform-course/tree/main/100_kubernetes_provider

Reference on how to expose aml service : 
- https://github.com/Azure/AML-Kubernetes/blob/master/docs/nginx-ingress-controller.md