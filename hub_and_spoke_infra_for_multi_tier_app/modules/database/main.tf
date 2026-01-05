resource "azurerm_cosmosdb_account" "cosmosdb" {
    name                = substr(lower(replace("${var.project_name}-cosmos-${var.environment}", "_", "-")), 0, 44)
    location            = var.location
    resource_group_name = var.resource_group
    offer_type          = "Standard"
    kind                = "GlobalDocumentDB"
    consistency_policy {
        consistency_level       = "Session"
    }

    identity {
        type = "SystemAssigned"
    }

    backup {
        type = "Periodic"
        retention_in_hours = 300 //sensitive data
    }

    public_network_access_enabled = false
    
    geo_location {
        location          = var.location
        failover_priority = 0
    }
  
}

resource "azurerm_cosmosdb_sql_database" "sqldb" {
    name                = lower(replace("${var.project_name}-sqldb-${var.environment}", "_", "-"))
    resource_group_name = var.resource_group
    account_name       = azurerm_cosmosdb_account.cosmosdb.name
}

resource "azurerm_cosmosdb_sql_container" "sqlcontainer" {
    name                = lower(replace("${var.project_name}-sqlcontainer-${var.environment}", "_", "-"))
    resource_group_name = var.resource_group
    account_name       = azurerm_cosmosdb_account.cosmosdb.name
    database_name      = azurerm_cosmosdb_sql_database.sqldb.name
    partition_key_paths = ["/partitionKey"]
    throughput         = 400

    indexing_policy {
        indexing_mode = "consistent"

        included_path {
            path = "/*"
        }

        included_path {
          path = "/included"
        }

        excluded_path {
            path = "/excluded/?"
        }
    }

}

// add database and virtual network cconnection

# resource "azurerm_cosmosdb_virtual_network_rule" "vnet_rule" {
#     resource_group_name  = var.resource_group.name
#     account_name        = azurerm_cosmosdb_account.cosmosdb.name
#     subnet_id           = var.subnet_ids[0]
#     ignore_missing_vnet_service_endpoint = true
# }









