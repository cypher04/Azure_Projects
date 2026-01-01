resource "azurerm_virtual_network" "vnet" {
    name                = "${var.project_name}-vnet-${var.environment}"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group
}

resource "azurerm_subnet" "subnet" {
    name                 = "${var.project_name}-subnet-vmss-${var.environment}"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = var.subnet_prefixes
}





