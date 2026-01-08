resource "azurerm_resource_group" "rg-main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
}


data "azurerm_client_config" "current" {

}


module "compute" {
  source              = "../../modules/compute"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group      = azurerm_resource_group.rg-main.name
  subnet_ids          = [module.networking.subnet_ids["web"], module.networking.subnet_ids["app"], module.networking.subnet_ids["database"]]
  administrator_login = var.administrator_login
  administrator_password = var.administrator_password
  server_name         = var.server_name
  database_name       = var.database_name

  depends_on = [module.database]
}

module "networking" {
  source          = "../../modules/networking"
  project_name    = var.project_name
  environment     = var.environment
  location        = var.location
  resource_group  = azurerm_resource_group.rg-main.name
  address_space   = var.address_space
  subnet_prefixes = var.subnet_prefixes
}

module "security" {
  source              = "../../modules/security"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group      = azurerm_resource_group.rg-main.name
  subnet_prefixes     = var.subnet_prefixes
  public_ip_id        = module.networking.public_ip_id
  subnet_ids          = [module.networking.subnet_ids["web"], module.networking.subnet_ids["app"], module.networking.subnet_ids["database"]]

  depends_on = [ module.networking ]
}






resource "azurerm_private_dns_zone" "acr_pdz" {
    name                = "privatelink.azurewebsites.net"
    resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz_vnet_link" {
    name                  = "${var.project_name}-pdz-vnet-link-${var.environment}"
    resource_group_name   = var.resource_group_name
    private_dns_zone_name = azurerm_private_dns_zone.acr_pdz.name
    virtual_network_id    = module.networking.vnet.id
    registration_enabled  = false
}

// Create Private Endpoint for Azure Container Registry
resource "azurerm_private_endpoint" "acr_private_endpoint" {
  name                = "${var.project_name}-pe-acr-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.acr_subnet_id

  private_service_connection {
    name                           = "${var.project_name}-psc-acr-${var.environment}"
    private_connection_resource_id = var.acr_id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
      name                 = "app-dns-zone-group"
      private_dns_zone_ids = [azurerm_private_dns_zone.acr_pdz.id]
  }
}


