resource "azurerm_container_registry" "acr" {
    name                = "${var.acr_name}acr"
    location            = var.location
    resource_group_name = var.resource_group_name
    sku                 = "Basic"
    admin_enabled       = true

    georeplications {
      location = "West Europe"
      zone_redundancy_enabled = true
    }

    georeplications {
      location = "North Europe"
      zone_redundancy_enabled = true
    }
}


resource "azurerm_log_analytics_workspace" "law" {
    name                = "${var.acr_name}-law"
    location            = var.location
    resource_group_name = var.resource_group_name
    sku                 = "PerGB2018"
    retention_in_days   = 30
  
}


resource "azurerm_container_app_environment" "aca-env" {
    name                = "${var.acr_name}-aca-env"
    location            = var.location
    resource_group_name = var.resource_group_name
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
    infrastructure_subnet_id = var.del_sub_id
    
}






resource "azurerm_container_app" "aca" {
    name = "${var.acr_name}-aca"
    container_app_environment_id = azurerm_container_app_environment.aca-env.id
    resource_group_name = var.resource_group_name
    revision_mode = "single"


    registry {
        server   = azurerm_container_registry.acr.login_server
        identity = "SystemAssigned"
    }

    template {
      container {
        name = "app"
        image = var.image
        cpu = 0.25
        memory = "1Gi"
      }
    }
}


