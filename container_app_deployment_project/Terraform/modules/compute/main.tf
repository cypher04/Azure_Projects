resource "azurerm_container_registry" "acr" {
    name                = "${var.acr_name}acr"
    location            = var.location
    resource_group_name = var.resource_group_name
    sku                 = "Premium"
    admin_enabled       = false

    public_network_access_enabled = false # Sensitive data, disable public network access


    identity {
        type = "SystemAssigned"
    }

            # georeplications {
            #   location = "West Europe"
            #   zone_redundancy_enabled = true
            # }

            # georeplications {
            #   location = "North Europe"   
            #   zone_redundancy_enabled = true
            #}
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
    internal_load_balancer_enabled = false
}

resource "azurerm_role_assignment" "acr_role_assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.aca.identity[0].principal_id
}




resource "azurerm_container_app" "aca" {
    name = "${var.aca_name}-aca"
    container_app_environment_id = azurerm_container_app_environment.aca-env.id
    resource_group_name = var.resource_group_name
    revision_mode = "Single"

    identity {
        type = "SystemAssigned"
    }


    registry {
        server               = azurerm_container_registry.acr.login_server
        username             = azurerm_container_registry.acr.admin_username
        password_secret_name = "acr-password"
    }

    secret {
        name  = "acr-password"
        value = azurerm_container_registry.acr.admin_password
    }

    ingress {
        external_enabled = true
        target_port       = 3000
        transport         = "auto"

        traffic_weight {
            percentage      = 100
            latest_revision = true
        }
    }

    template {
      container {
        name = "app"
        image = var.image
        cpu = 0.5
        memory = "1Gi"
      }
    }
}


