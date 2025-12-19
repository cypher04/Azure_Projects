# output "subnet_id" {
#     description = "The subnet ID where the compute resources are deployed"
#     value       = var.subnet_id
# }

// deployment outputs
output "subnet_ids" {
  description = "The subnet prefixes used in the deployment"
  value       = var.subnet_prefixes
}

output "mssql_server_name" {
  description = "The name of the MSSQL Server"
  value       = var.mssql_server_name
}

output "mssql_db_name" {
  description = "The name of the MSSQL Database"
  value       = var.mssql_db_name
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = var.resource_group_name
}


