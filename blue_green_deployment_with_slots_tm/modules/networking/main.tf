

resource "azurerm_virtual_network" "vnet" {
    name                = "${var.project_name}-vnet-${var.environment}"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group
}

resource "azurerm_subnet" "web" {
    name                 = "${var.project_name}-subnet-web-${var.environment}"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["web"]]
}

resource "azurerm_subnet" "app" {
    name                 = "${var.project_name}-subnet-app-${var.environment}"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["app"]]
}

resource "azurerm_subnet" "database" {
    name                 = "${var.project_name}-subnet-database-${var.environment}"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["database"]]
}


resource "azurerm_public_ip" "pip" {
  name                = "${var.project_name}-pip-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
}

