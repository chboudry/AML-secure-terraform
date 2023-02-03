variable "name" {
  type        = string
  description = "Name of the deployment"
  default     = "chbou"
}

variable "location" {
  type        = string
  description = "Location of the resources"
  default     = "westeurope"

}

#Hub Virtual Network
variable "vnet_hub_address_space" {
  type        = list(string)
  description = "Address space of the Hub virtual network"
  default     = ["10.40.0.0/16"]
}

variable "jumphost_subnet_address_space" {
  type        = list(string)
  description = "Address space of the Jumphost subnet"
  default     = ["10.40.2.0/24"]
}

variable "bastion_subnet_address_space" {
  type        = list(string)
  description = "Address space of the bastion subnet"
  default     = ["10.40.3.0/24"]
}

variable "firewall_subnet_address_space" {
  type        = list(string)
  description = "Address space of the Az Fiewall subnet"
  default     = ["10.40.4.0/24"]
}

#Spoke ML
variable "vnet_ml_address_space" {
  type        = list(string)
  description = "Address space of the spoke virtual network"
  default     = ["10.41.0.0/16"]
}

variable "workspace_subnet_address_space" {
  type        = list(string)
  description = "Address space of the ML workspace subnet"
  default     = ["10.41.0.0/24"]
}

variable "training_subnet_address_space" {
  type        = list(string)
  description = "Address space of the training subnet"
  default     = ["10.41.1.0/24"]
}

variable "inference_subnet_address_space" {
  type        = list(string)
  description = "Address space of the inference subnet"
  default     = ["10.41.2.0/24"]
}

#Spoke AKS
variable "vnet_aks_address_space" {
  type        = list(string)
  description = "Address space of the spoke virtual network"
  default     = ["10.42.0.0/16"]
}

variable "aks_subnet_address_space" {
  type        = list(string)
  description = "Address space of the training subnet"
  default     = ["10.42.0.0/16"]
}

#Image Build Compute
variable "image_build_compute_name" {
  type        = string
  description = "Name of the compute cluster to be created and set to build docker images"
  default     = "image-builder"
}

# DSVM
variable "dsvm_name" {
  type        = string
  description = "Name of the Data Science VM"
  default     = "chbouvmdsvm01"
}

variable "dsvm_admin_username" {
  type        = string
  description = "Admin username of the Data Science VM"
  default     = "azureadmin"
}

variable "dsvm_host_password" {
  type        = string
  description = "Password for the admin username of the Data Science VM"
  sensitive   = true
}