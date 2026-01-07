


# output "network_security_group_id" {
#   description = "The ID of the Network Security Group"
#   value       = module.security.network_security_group_id
# }

# output "public_ip_id" {
#   description = "The ID of the Public IP"
#   value       = module.networking.public_ip_id
# }


output "sql_database_id" {
  description = "The ID of the SQL Database"
  value       = module.database.database_sql_database_id
}

output "resource_group_name" {
  description = "The name of the Resource Group"
  value       = azurerm_resource_group.rg-main.name
}

output "location" {
  description = "The location of the Resource Group"
  value       = azurerm_resource_group.rg-main.location
}

output "project_name" {
  description = "The project name"
  value       = var.project_name
}

output "environment" {
  description = "The deployment environment"
  value       = var.environment
}

output "cosmosdb_private_dns_zone_id" {
  description = "The ID of the Cosmos DB private DNS zone"
  value       = module.compute.cosmosdb_private_dns_zone_id
}

output "hub_subnet_id" {
    description = "The ID of the Hub Subnet"
    value       = var.hub_subnet_id
}

output "network_security_group_id" {
  description = "The ID of the Network Security Group"
  value       = module.security.network_security_group_id
}

output "public_ip_id" {
    description = "The ID of the Public IP"
    value       = module.networking.public_ip_id
}


