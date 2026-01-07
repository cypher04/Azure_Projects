output "database_account_id" {
    value = azurerm_cosmosdb_account.cosmosdb.id
}

output "database_sql_database_id" {
    value = azurerm_cosmosdb_sql_database.sqldb.id
}

output "database_sql_container_id" {
    value = azurerm_cosmosdb_sql_container.sqlcontainer.id
}

output "database_account_endpoint" {
    value = azurerm_cosmosdb_account.cosmosdb.endpoint
}



