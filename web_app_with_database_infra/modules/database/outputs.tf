// output for database
output "server_id" {
    description = "The ID of the MSSQL Server"
    value       = azurerm_mssql_server.mssql_server.id
  
}

output "database_id" {
    description = "The ID of the MSSQL Database"
    value       = azurerm_mssql_database.msdb.id
  
}

output "mssql_server_id" {
    description = "The id of the MSSQL Server"
    value       = azurerm_mssql_server.mssql_server.id
}
