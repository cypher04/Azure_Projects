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

# variable "tags" {
#     description = "A map of tags to assign to resources"
#     type        = map(string)
# }


variable "subnet_ids" {
    description = "A list of subnet IDs"
    type        = list(string)
}




variable "vnet_spoke_1_id" {
    description = "The ID of the Spoke 1 Virtual Network"
    type        = string
}

variable "cosmosdb_id" {
    description = "The ID of the Cosmos DB account"
    type        = string
}

variable "delegation_subnet_id" {
    description = "The ID of the delegation subnet for VNet integration"
    type        = string
}

variable "vnet_hub_id" {
    description = "The ID of the Hub Virtual Network"
    type        = string
}