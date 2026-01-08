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

variable "image" {
    description = "The container image to deploy in the Container App."
    type        = string
}

variable "del_sub_id" {
    description = "The ID of the delegated subnet for the Container App Environment."
    type        = string
}   

variable "aca_name" {
    description = "The name of the Azure Container App."
    type        = string
}
