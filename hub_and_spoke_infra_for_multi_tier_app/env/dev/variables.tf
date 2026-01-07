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
    default     = ""
}


variable "network_security_group_id" {
    description = "The ID of the Network Security Group"
    type        = string
    default     = ""
}

variable "vnet_spoke_1_id" {
    description = "The ID of the Spoke 1 Virtual Network"
    type        = string
    default     = ""
}

variable "cosmos_db_account_id" {
    description = "The ID of the Cosmos DB account"
    type        = string
    default     = ""
}

variable "hub_subnet_id" {
    description = "The ID of the Hub Subnet"
    type        = string
    default = ""
}

# variable "webapp_private_dns_zone_id" {
#     description = "The ID of the web app private DNS zone"
#     type        = string
#     default     = ""
# }

# variable "cosmosdb_private_dns_zone_id" {
#     description = "The ID of the cosmosdb private DNS zone"
#     type        = string
# }

variable "vnet_hub_id" {
    description = "The ID of the Hub Virtual Network"
    type        = string
    default = ""
}

# variable "app_service_id" {
#     description = "The ID of the App Service for VNet integration"
#     type        = string
# }