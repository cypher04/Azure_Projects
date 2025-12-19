resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
  }
}

data "azurerm_client_config" "current" {
  
}

module "compute" {
  source = "../../modules/compute"

  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  environment            = var.environment
  subnet_id              = module.networking.app
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
#   subnet_prefixes        = [var.subnet_prefixes["app"]]
  mssql_server_name      = var.mssql_server_name
  mssql_db_name          = var.mssql_db_name
  mssql_server_id        = module.database.server_id
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  address_space       = var.address_space
  subnet_prefixes     = var.subnet_prefixes
  subnet_ids           = module.networking.subnet_ids

}

module "security" {
  source = "../../modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  subnet_ids          = module.networking.subnet_ids
  subnet_prefixes     = var.subnet_prefixes
  public_ip           = module.networking.public_ip
  depends_on          = [module.networking]
  pip_id = module.networking.pip_id
}

module "database" {
  source = "../../modules/database"

  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  subnet_id              = module.networking.database
  environment            = var.environment
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
  subnet_prefixes        = [var.subnet_prefixes["database"]]
  mssql_server_name      = var.mssql_server_name
  mssql_db_name          = var.mssql_db_name
  depends_on             = [module.networking]
}





