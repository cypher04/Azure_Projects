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

variable "delegation_subnet" {
    description = "A list of subnet prefixes for delegated subnets"
    type        = list(string)   
}

variable "subnet_ids" {
    description = "A list of subnet IDs"
    type        = list(string)
    default     = []
}

variable "public_ip_id" {
    description = "The ID of the Public IP"
    type        = string
}


variable "network_security_group_id" {
    description = "The ID of the Network Security Group"
    type        = string
}

variable "vnet_spoke_1_id" {
    description = "The ID of the Spoke 1 Virtual Network"
    type        = string
    default     = ""
}

