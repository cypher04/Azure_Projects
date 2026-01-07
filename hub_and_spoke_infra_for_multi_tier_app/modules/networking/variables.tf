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

# variable "tags" {
#     description = "A map of tags to assign to resources"
#     type        = map(string)
# }

variable "subnet_ids" {
    description = "A list of subnet IDs"
    type        = list(string)
}

variable "delegation_subnet" {
    description = "The delegation for the subnet"
    type        = list(string)
}

variable "app_service_id" {
    description = "The ID of the App Service for VNet integration"
    type        = string
    default     = ""
}

variable "cosmosdb_account_id" {
    description = "The ID of the Cosmos DB account for private endpoint"
    type        = string
    default     = ""
}

variable "vnet_spoke_1_id" {
    description = "The ID of the Spoke 1 Virtual Network"
    type        = string
    default     = ""
}

variable "vnet_hub_id" {
    description = "The ID of the Hub Virtual Network"
    type        = string
    default     = ""
}

variable "hub_subnet_id" {
    description = "The ID of the Hub Subnet"
    type        = string
    default     = ""
}