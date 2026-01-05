resource "azurerm_virtual_network" "vnet-hub" {
    name                = "${var.project_name}-${var.environment}-vnet"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group.name
    
    # tags = var.tags
}

resource "azurerm_subnet" "hub-subnet" {
    name                 = "${var.project_name}-${var.environment}-subnet-web"
    resource_group_name  = var.resource_group.name
    virtual_network_name = azurerm_virtual_network.vnet-hub.name
    address_prefixes     = [var.subnet_prefixes[0]]
    
}


resource "azurerm_subnet" "del-subnet" {
    name                 = "${var.project_name}-subnet-vmss-${var.environment}"
    resource_group_name  = var.resource_group.name
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
    resource_group_name = var.resource_group.name
}

resource "azurerm_subnet" "subnet-spoke-1-web" {
    name                 = "${var.project_name}-subnet-vmss-${var.environment}"
    resource_group_name  = var.resource_group.name
    virtual_network_name = azurerm_virtual_network.vnet-spoke-1.name
    address_prefixes     = [var.subnet_prefixes[1]]
}

resource "azurerm_virtual_network" "vnet-spoke-2" {
    name                = "${var.project_name}-vnet-${var.environment}"
    address_space       = var.address_space
    location            = var.location
    resource_group_name = var.resource_group.name
}
resource "azurerm_subnet" "subnet-spoke-2-app" {
    name                 = "${var.project_name}-subnet-vmss-${var.environment}"
    resource_group_name  = var.resource_group.name
    virtual_network_name = azurerm_virtual_network.vnet-spoke-2.name
    address_prefixes     = [var.subnet_prefixes[2]]
}

resource "azurerm_virtual_network_peering" "hub-to-spoke1" {
    name                      = "${var.project_name}-hub-to-spoke1-peering-${var.environment}"
    resource_group_name       = var.resource_group.name
    virtual_network_name      = azurerm_virtual_network.vnet-hub.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-spoke-1.id
}

resource "azurerm_virtual_network_peering" "spoke1-to-hub" {
    name                      = "${var.project_name}-spoke1-to-hub-peering-${var.environment}"
    resource_group_name       = var.resource_group.name
    virtual_network_name      = azurerm_virtual_network.vnet-spoke-1.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-hub.id
}

resource "azurerm_virtual_network_peering" "hub-to-spoke2" {
    name                      = "${var.project_name}-hub-to-spoke2-peering-${var.environment}"
    resource_group_name       = var.resource_group.name
    virtual_network_name      = azurerm_virtual_network.vnet-hub.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-spoke-2.id
}

resource "azurerm_virtual_network_peering" "spoke2-to-hub" {
    name                      = "${var.project_name}-spoke2-to-hub-peering-${var.environment}"
    resource_group_name       = var.resource_group.name
    virtual_network_name      = azurerm_virtual_network.vnet-spoke-2.name
    remote_virtual_network_id = azurerm_virtual_network.vnet-hub.id
}


resource "azurerm_public_ip" "public_ip" {
    name                = "${var.project_name}-public-ip-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group.name
    allocation_method   = "Static"
    sku                 = "Standard"
}


// finally, connect the App Service to the VNet using Swift Connection for outbound traffic
resource "azurerm_app_service_virtual_network_swift_connection" "name" {
    app_service_id      = module.compute.linux_web_app_id
    subnet_id           = azurerm_subnet.del-subnet.id
}

// Create Private Endpoint for App Service in Spoke 2 VNet for inbound traffic
resource "azurerm_private_endpoint" "pe-appservice" {
    name                = "${var.project_name}-pe-appservice-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group.name
    subnet_id           = azurerm_subnet.subnet-spoke-2-app.id

    private_service_connection {
        name                           = "${var.project_name}-psc-appservice-${var.environment}"
        private_connection_resource_id = module.compute.linux_web_app.id
        is_manual_connection           = false
        subresource_names              = ["sites"]
    }
}



