variable "location" {
    description = "The Azure location where resources will be deployed."
    type        = string
    default     = "East US"
}

variable "environment" {
    description = "The deployment environment (e.g., dev, prod)."
    type        = string
    default     = "dev"
}

variable "project_name" {
    description = "The name of the project."
    type        = string
}


variable "resource_group_name" {
    description = "The name of the resource group in which to create the AKS cluster."
    type        = string
}


variable "address_space" {
  description = "The address space for the virtual network."
  type        = list(string)
}


variable "subnet_prefixes" {
  description = "A map of subnet names to their respective prefixes."
  type        = map(string)
}


variable "acr_name" {
    description = "The name of the Azure Container Registry."
    type        = string
}

variable "vnet_id" {
    description = "The ID of the virtual network."
    type        = string
}

variable "acr_subnet_id" {
    description = "The ID of the subnet for the Azure Container Registry."
    type        = string
}

variable "acr_id" {
    description = "The ID of the Azure Container Registry."
    type        = string
}
  



