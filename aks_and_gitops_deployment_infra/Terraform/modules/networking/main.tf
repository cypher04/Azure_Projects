resource "azurerm_virtual_network" "vnet" {
    name                = "${var.project_name}-vnet-${var.environment}"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "web" {
    name                 = "${var.project_name}-subnet-web-${var.environment}"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["web"]]
}

resource "azurerm_subnet" "del_sub" {
    name                 = "${var.project_name}-subnet-del-${var.environment}"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["del_sub"]]


    delegation {
        name = "cont_app_delegation"

        service_delegation {
            name = "Microsoft.ContainerService/managedClusters"
            actions = [
                "Microsoft.Network/virtualNetworks/subnets/join/action",
                "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
            ]
        }
    }
}


resource "azurerm_subnet" "acr_sub" {
    name                 = "${var.project_name}-subnet-db-${var.environment}"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = [var.subnet_prefixes["acr_sub"]]
}