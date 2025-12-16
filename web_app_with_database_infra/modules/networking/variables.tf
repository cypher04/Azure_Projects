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