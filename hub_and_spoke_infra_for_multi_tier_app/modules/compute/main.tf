resource "azurerm_service_plan" "service_plan" {
  name                = "${var.project_name}-serviceplan-${var.environment}"
  resource_group_name = var.resource_group
  location            = var.location
  os_type             = "Linux"
  sku_name            = "P1v2"
}

resource "azurerm_app_service_connection" "app_service_connection" {
    name               = "database-connection"
    app_service_id     = azurerm_linux_web_app.web_app.id
    target_resource_id = module.database.database_id
    authentication {
        type = "systemAssignedIdentity"
    }
}

resource "azurerm_linux_web_app" "web_app" {
    name                = "${var.project_name}-webapp-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group.name
    service_plan_id     = azurerm_service_plan.service_plan.id

    site_config {
        linux_fx_version = "NODE|14-lts"
    }

    identity {
        type = "SystemAssigned"
    }

    app_settings = {
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    }
}




