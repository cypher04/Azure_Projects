resource "azurerm_virtual_network" "vnet-hub" {
    name                = "${var.project_name}-${var.environment}-vnet"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group
    
    # tags = var.tags
}

resource "azurerm_subnet" "hub-subnet-database" {
    name                 = "${var.project_name}-${var.environment}-subnet-database"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vnet-hub.name
    address_prefixes     = [var.subnet_prefixes[0]]
    
}


resource "azurerm_subnet" "del-subnet" {
    name                 = "${var.project_name}-subnet-vmss-${var.environment}"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vnet-hub.name
    address_prefixes     = var.delegation_subnet
delegation {
    name = "${var.project_name}-delegation-${var.environment}"
    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
    }
}

}

resource "azurerm_virtual_network" "vnet-spoke-1" {
    name                = "${var.project_name}-vnet-${var.environment}"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group
}

resource "azurerm_subnet" "subnet-spoke-1-web" {
    name                 = "${var.project_name}-subnet-vmss-${var.environment}"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vnet-spoke-1.name
    address_prefixes     = [var.subnet_prefixes[1]]
}

resource "azurerm_virtual_network" "vnet-spoke-2" {
    name                = "${var.project_name}-vnet-${var.environment}"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group
}
resource "azurerm_subnet" "subnet-spoke-2-app" {
    name                 = "${var.project_name}-subnet-vmss-${var.environment}"
    resource_group_name  = var.resource_group
    virtual_network_name = azurerm_virtual_network.vnet-spoke-2.name
    address_prefixes     = [var.subnet_prefixes[2]]
}



// VNet Peerings between Hub and Spokes
resource "azurerm_virtual_network_peering" "hub-to-spoke1" {
    name                      = "${var.project_name}-hub-to-spoke1-peering-${var.environment}"
    resource_group_name       = var.resource_group
    virtual_network_name      = azurerm_virtual_network.vnet-hub.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-spoke-1.id
}

resource "azurerm_virtual_network_peering" "spoke1-to-hub" {
    name                      = "${var.project_name}-spoke1-to-hub-peering-${var.environment}"
    resource_group_name       = var.resource_group
    virtual_network_name      = azurerm_virtual_network.vnet-spoke-1.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-hub.id
}

resource "azurerm_virtual_network_peering" "hub-to-spoke2" {
    name                      = "${var.project_name}-hub-to-spoke2-peering-${var.environment}"
    resource_group_name       = var.resource_group
    virtual_network_name      = azurerm_virtual_network.vnet-hub.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-spoke-2.id
}

resource "azurerm_virtual_network_peering" "spoke2-to-hub" {
    name                      = "${var.project_name}-spoke2-to-hub-peering-${var.environment}"
    resource_group_name       = var.resource_group
    virtual_network_name      = azurerm_virtual_network.vnet-spoke-2.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-hub.id
}

resource "azurerm_virtual_network_peering" "spoke1-to-spoke2-peering" {
    name                      = "${var.project_name}-spoke1-to-spoke2-peering-${var.environment}"
    resource_group_name       = var.resource_group
    virtual_network_name      = azurerm_virtual_network.vnet-spoke-1.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-spoke-2.id
}


resource "azurerm_virtual_network_peering" "spoke2-to-spoke1-peering" {
    name                      = "${var.project_name}-spoke2-to-spoke1-peering-${var.environment}"
    resource_group_name       = var.resource_group
    virtual_network_name      = azurerm_virtual_network.vnet-spoke-2.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-spoke-1.id
}

// Create a Public IP for the App Service Environment
resource "azurerm_public_ip" "public_ip" {
    name                = "${var.project_name}-public-ip-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group
    allocation_method   = "Static"
    sku                 = "Standard"
}

output "hub_subnet_database_id" {
    value = azurerm_subnet.hub-subnet-database.id
}



