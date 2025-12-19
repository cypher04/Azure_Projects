variable "resource_group_name" {
    description = "The name of the resource group"
    type        = string
}

variable "location" {
    description = "The location where resources will be created"
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
    description = "The address prefixes for the subnet"
    type        = map(string)
}

variable "subnet_ids" {
    description = "The IDs of the subnets"
    type        = list(string)
}