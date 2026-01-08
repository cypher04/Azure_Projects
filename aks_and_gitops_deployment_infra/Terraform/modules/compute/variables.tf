variable "cluster_name" {
    description = "The name of the AKS cluster."
    type        = string
}

variable "location" {
    description = "The Azure region where the AKS cluster will be deployed."
    type        = string
}

variable "resource_group_name" {
    description = "The name of the resource group in which to create the AKS cluster."
    type        = string
}

variable "dns_prefix" {
    description = "The DNS prefix for the AKS cluster."
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

