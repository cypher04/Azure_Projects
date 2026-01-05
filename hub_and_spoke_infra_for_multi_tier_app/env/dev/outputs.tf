


output "network_security_group_id" {
  description = "The ID of the Network Security Group"
  value       = module.security.network_security_group_id
}

output "public_ip_id" {
  description = "The ID of the Public IP"
  value       = module.networking.public_ip_id
}


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

