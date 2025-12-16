
resource "azurerm_app_service_plan" "  main" {
        name                = "asp-${var.environment}"
        location            = var.location
        resource_group_name = var.resource_group_name
        
        sku {
            tier = "Standard"
            size = "S1"
        }
}
  
resource "azurerm_linux_web_app" "liweb" {
    name                = "webapp-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group_name
    service_plan_id     = azurerm_app_service_plan.main.id
    
    site_config {
        linux_fx_version = "NODE|14-lts"
    }
    
    app_settings = {
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    }
}









