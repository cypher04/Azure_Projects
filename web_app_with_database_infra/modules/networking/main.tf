resource "azurerm_virtual_network" "main" {
    name                = "vnet-${var.environment}"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "main" {
    name                 = "subnet-${var.environment}"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = [var.subnet_prefixes["main"]]
}

resource "azurerm_subnet" "database" {
    name                 = "subnet-db-${var.environment}"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = [var.subnet_prefixes["database"]]
}

resource "azurerm_subnet" "app" {
    name                 = "subnet-app-${var.environment}"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = [var.subnet_prefixes["app"]]
}

resource "azurerm_public_ip" "pip" {
    name                = "pip-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group_name
    allocation_method   = "Dynamic"
}

