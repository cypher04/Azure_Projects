resource "azurerm_resource_group" "main" {
    name     = var.resource_group_name
    location = var.location

    tags = {
        environment = var.environment
    }
}

module "compute" {
    source = "../../modules/compute"

    resource_group_name = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location
    environment         = var.environment

}

module "networking" {
    source = "../../modules/networking"
    
        resource_group_name = azurerm_resource_group.main.name
        location            = azurerm_resource_group.main.location
        environment         = var.environment
        address_space = var.address_space
        subnet_prefixes = var.subnet_prefixes
}




