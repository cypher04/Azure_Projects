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
    target_resource_id = var.cosmosdb_id
    authentication {
        type = "systemAssignedIdentity"
    }
}

resource "azurerm_linux_web_app" "web_app" {
    name                = lower(replace("${var.project_name}-webapp-${var.environment}", "_", "-"))
    location            = var.location
    resource_group_name = var.resource_group
    service_plan_id     = azurerm_service_plan.service_plan.id
    client_certificate_enabled = true
    client_certificate_mode = "Required"
    
    auth_settings {
      enabled = true
      unauthenticated_client_action = "RedirectToLoginPage"

    }

site_config {

}

    identity {
        type = "SystemAssigned"
    }

    app_settings = {
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    }
}


resource "azurerm_private_dns_zone" "pdz" {
    name                = "privatelink.azurewebsites.net"
    resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_vnet_link" {
    name                  = "${var.project_name}-pdz-vnet-link-${var.environment}"
    resource_group_name   = var.resource_group
    private_dns_zone_name = azurerm_private_dns_zone.pdz.name
    virtual_network_id    = var.vnet_spoke_1_id
    registration_enabled  = false
}

# resource "azurerm_dns_zone_group" "name" {
#     name                 = "${var.project_name}-dzg-${var.environment}"
#     private_endpoint_id  = azurerm_private_endpoint.pe-appservice.id

#     private_dns_zone_config {
#         name                  = "pdz-config"
#         private_dns_zone_id   = azurerm_private_dns_zone.pdz.id
#     }
# }






