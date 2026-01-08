variable "acr_name" {
    description = "The name of the Azure Container Registry."
    type        = string
}

variable "location" {
    description = "The Azure region where the Azure Container Registry will be deployed."
    type        = string
}

variable "resource_group_name" {
    description = "The name of the resource group in which to create the Azure Container Registry."
    type        = string
}

variable "dns_prefix" {
    description = "The DNS prefix for the Azure Container Registry."
    type        = string
}

variable "node_count" {
    description = "The number of nodes in the default node pool."
    type        = number
    default     = 3
}   

variable "vm_size" {
    description = "The size of the Virtual Machines in the default node pool."
    type        = string
}

variable "image" {
    description = "The container image to deploy in the Container App."
    type        = string
}

variable "del_sub_id" {
    description = "The ID of the delegated subnet for the Container App Environment."
    type        = string
}   

