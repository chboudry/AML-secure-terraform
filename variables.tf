variable "name" {
  type        = string
  description = "Name of the deployment"
  default     = "chbou"
}

variable "environment" {
  type        = string
  description = "Name of the environment"
  default     = "test2"
}

variable "location" {
  type        = string
  description = "Location of the resources"
  default     = "westeurope"

}

#Spoke Virtual Network

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space of the spoke virtual network"
  default     = ["10.30.0.0/16"]
}

variable "training_subnet_address_space" {
  type        = list(string)
  description = "Address space of the training subnet"
  default     = ["10.30.1.0/24"]
}

variable "inference_subnet_address_space" {
  type        = list(string)
  description = "Address space of the inference subnet"
  default     = ["10.30.2.0/24"]
}

variable "ml_subnet_address_space" {
  type        = list(string)
  description = "Address space of the ML workspace subnet"
  default     = ["10.30.0.0/24"]
}

#Hub Virtual Network
variable "vnet_hub_address_space" {
  type        = list(string)
  description = "Address space of the Hub virtual network"
  default     = ["10.31.0.0/16"]
}

variable "jumphost_subnet_address_space" {
  type        = list(string)
  description = "Address space of the Jumphost subnet"
  default     = ["10.31.2.0/24"]
}

variable "bastion_subnet_address_space" {
  type        = list(string)
  description = "Address space of the bastion subnet"
  default     = ["10.31.3.0/24"]
}

variable "firewall_subnet_address_space" {
  type        = list(string)
  description = "Address space of the Az Fiewall subnet"
  default     = ["10.31.4.0/24"]
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