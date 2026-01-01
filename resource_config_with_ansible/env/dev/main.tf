

resource "azurerm_resource_group" "rg-main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  
 
  tags = var.tags
}


data "azurerm_client_config" "current" {
}


module "compute" {
  source              = "../../modules/compute"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  subnet_ids          = module.networking.subnet_ids
  administrator_login = var.administrator_login
  administrator_password = var.administrator_password
  ssh_public_key_path = var.ssh_public_key_path
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
  public_ip_id        = module.networking.public_ip_id
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

module "database" {
  source              = "../../modules/database"
  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.rg-main.name
  subnet_ids          = [module.networking.subnet_ids["web"], module.networking.subnet_ids["app"], module.networking.subnet_ids["database"]]
  administrator_login = var.administrator_login
  administrator_password = var.administrator_password

}
