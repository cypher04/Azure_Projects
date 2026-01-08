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