variable "resource_group" {
    description = "The name of the resource group"
    type        = string
}

variable "location" {
    description = "The Azure region to deploy resources"
    type        = string
}

variable "project_name" {
    description = "The name of the project"
    type        = string
}

variable "environment" {
    description = "The deployment environment (e.g., dev, prod)"
    type        = string
}

variable "address_space" {
    description = "The address space for the virtual network"
    type        = list(string)
}

variable "subnet_prefixes" {
    description = "A list of subnet prefixes"
    type        = list(string)
}

variable "tags" {
    description = "A map of tags to assign to resources"
    type        = map(string)
}

