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

variable "tags" {
    description = "A map of tags to assign to resources"
    type        = map(string)
}

variable "network_security_group_name" {
    description = "The name of the network security group"
    type        = string
    default     = "nsg-default"
}

variable "subnet_ids" {
    description = "A list of subnet IDs to associate with the network security group"
    type        = list(string)
}


variable "subnet_prefixes" {
    description = "A list of subnet prefixes"
    type        = list(string)
}