



resource "azurerm_mssql_server" "mssql_server" {
    name                         = "mssql-server-${var.environment}"
    resource_group_name          = var.resource_group_name
    location                     = var.location
    version                      = "12.0"
    administrator_login          = var.administrator_login
    administrator_login_password = var.administrator_password  
    public_network_access_enabled = false

    identity {
        type = "SystemAssigned"
    }


    
    tags = {
        environment = var.environment
    }

}

resource "azurerm_mssql_database" "msdb" {
    name                = "maindb"
    server_id           = azurerm_mssql_server.mssql_server.id
    sku_name           = "S0"
    collation          = "SQL_Latin1_General_CP1_CI_AS"
    max_size_gb       = 2
    license_type      = "BasePrice"
    enclave_type = "VBS"

    tags = {
        environment = var.environment
    }   
}

resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
    name      = "sql-vnet-rule-${var.environment}"
    server_id = azurerm_mssql_server.mssql_server.id
    subnet_id = var.subnet_id
}



