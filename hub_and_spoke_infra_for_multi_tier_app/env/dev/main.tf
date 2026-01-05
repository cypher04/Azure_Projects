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
  delegation_subnet = var.delegation_subnet

  depends_on = [module.networking]
}


module "networking" {
  source              = "../../modules/networking"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  subnet_prefixes     = var.subnet_prefixes
  address_space       = var.address_space
  resource_group      = azurerm_resource_group.rg-main.name
  delegation_subnet = var.delegation_subnet
  subnet_ids = var.subnet_ids
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
  subnet_ids          = var.subnet_ids
  public_ip_id = module.networking.public_ip.id
  depends_on = [ module.networking ]
}