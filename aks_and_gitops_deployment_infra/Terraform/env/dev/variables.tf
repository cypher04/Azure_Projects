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



  



