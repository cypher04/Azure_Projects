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
  subnet_ids          = var.subnet_ids
  delegation_subnet_id = module.networking.delegation_subnet_id
  vnet_spoke_1_id     = module.networking.virtual_network_id
  vnet_hub_id         = module.networking.vnet_hub_id
  cosmosdb_id         = module.database.database_account_id

  depends_on = [module.networking, module.database]
}


module "networking" {
  source              = "../../modules/networking"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  subnet_prefixes     = var.subnet_prefixes
  address_space       = var.address_space
  resource_group      = azurerm_resource_group.rg-main.name
  delegation_subnet   = var.delegation_subnet
  subnet_ids          = var.subnet_ids
}


module "database" {
  source              = "../../modules/database"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group = azurerm_resource_group.rg-main.name
  subnet_ids          = var.subnet_ids

}


module "security" {
  source              = "../../modules/security"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group      = azurerm_resource_group.rg-main.name
  subnet_prefixes     = var.subnet_prefixes
  subnet_ids          = [
    module.networking.hub_subnet_database_id,
    module.networking.subnet_id_spoke_1_web,
    module.networking.subnet_id_spoke_2_app
  ]
  public_ip_id = module.networking.public_ip_id
  depends_on = [ module.networking ]
}


# VNet Integration and Private Endpoints
# These are created at the root level to avoid circular dependencies between modules

// Connect the App Service to the VNet using Swift Connection for outbound traffic
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_connection" {
  app_service_id = module.compute.linux_web_app_id
  subnet_id      = module.networking.delegation_subnet_id

  depends_on = [module.compute, module.networking]
}

// create load balancer

resource "azurerm_lb" "loadbalancer" {
  name                = "${var.project_name}-lb-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = module.networking.public_ip_id
  }
}


// create private link service for load balancer
resource "azurerm_private_link_service" "plservice" {
  name                = "${var.project_name}-pls-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  
  nat_ip_configuration {
    name = module.networking.public_ip_id
    primary = true
    subnet_id = module.networking.subnet_id_spoke_1_web
  }


  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.loadbalancer.frontend_ip_configuration[0].id
  ]
  
}




// Create Private Endpoint for App Service in Spoke 2 VNet for inbound traffic
resource "azurerm_private_endpoint" "pe-appservice" {
  name                = "${var.project_name}-pe-appservice-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  subnet_id           = module.networking.subnet_id_spoke_2_app

  private_service_connection {
    name                           = "${var.project_name}-psc-appservice-${var.environment}"
    private_connection_resource_id = azurerm_private_link_service.plservice.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
      name                 = "app-dns-zone-group"
      private_dns_zone_ids = [module.compute.webapp_private_dns_zone_id]
  }
  

  depends_on = [module.compute, module.networking]
}

// Create Private Endpoint for Cosmos DB in Hub VNet for secure database access
resource "azurerm_private_endpoint" "pe-cosmosdb" {
  name                = "${var.project_name}-pe-cosmosdb-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  subnet_id           = module.networking.hub_subnet_id

  private_service_connection {
    name                           = "${var.project_name}-psc-cosmosdb-${var.environment}"
    private_connection_resource_id = azurerm_private_link_service.plservice.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
      name                 = "cosmos-dns-zone-group"
      private_dns_zone_ids = [module.compute.cosmosdb_private_dns_zone_id]
  }

  depends_on = [module.database, module.networking]
}