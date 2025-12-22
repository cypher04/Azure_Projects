
resource "azurerm_app_service_plan" "main" {
        name                = "asp-${var.environment}"
        location            = var.location
        resource_group_name = var.resource_group_name

        sku {
            tier = "Standard"
            size = "S1"
        }
}

resource "azurerm_app_service_connection" "database" {
    name               = "database-connection"
    app_service_id     = azurerm_linux_web_app.liweb.id
    target_resource_id = var.mssql_server_id
    authentication {
        type = "systemAssignedIdentity"
    }
}
  
resource "azurerm_linux_web_app" "liweb" {
    name                = "webapp-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group_name
    service_plan_id     = azurerm_app_service_plan.main.id
    client_certificate_enabled = true
    client_certificate_mode = "Required"
    identity {
        type = "SystemAssigned"
    }

    auth_settings {
        enabled = true
        unauthenticated_client_action = "RedirectToLoginPage"
    }
    
    site_config {
        
    }
    
    app_settings = {
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
        "DATABASE_URL" = "Server=${var.mssql_server_name};Database=${var.mssql_db_name};User Id=${var.administrator_login};Password=${var.administrator_password};"
        "WEBSITES_PORT" = "3000"
    }
}

resource "azurerm_app_service_virtual_network_swift_connection" "asvnet" {
    app_service_id = azurerm_linux_web_app.liweb.id
    subnet_id      = var.subnet_id
}













