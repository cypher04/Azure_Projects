resource "azurerm_network_security_group" "nsg-hub" {
    name                = "${var.project_name}-nsg-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group.name
}


resource "azurerm_network_security_group" "nsg-web" {
    name                = "${var.project_name}-nsg-web-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group.name
  
}

resource "azurerm_network_security_group" "nsg-app" {
    name                = "${var.project_name}-nsg-app-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group.name
}


resource "azurerm_subnet_network_security_group_association" "web-nsg-association" {
    subnet_id                 = [module.networking.subnet_ids[2]]
    network_security_group_id = azurerm_network_security_group.nsg-web.id
}

resource "azurerm_subnet_network_security_group_association" "app-nsg-association" {
    subnet_id                 = [module.networking.subnet_ids[1]]
    network_security_group_id = azurerm_network_security_group.nsg-app.id
}

resource "azurerm_subnet_network_security_group_association" "hub-nsg-association" {
    subnet_id                 = [module.networking.subnet_ids[0]]
    network_security_group_id = azurerm_network_security_group.nsg-hub.id
  
}

resource "azurerm_network_security_rule" "allow_http" {
    name                        = "Allow-HTTP"
    priority                    = 100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    network_security_group_name = azurerm_network_security_group.nsg-web
    resource_group_name         = var.resource_group.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
    name                        = "Allow-SSH"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    network_security_group_name = azurerm_network_security_group.nsg-app.name
    resource_group_name         = var.resource_group.name
}

resource "azurerm_network_security_rule" "allow_sql" {
    name                        = "Allow-SQL"
    priority                    = 120
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "1433"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    network_security_group_name = azurerm_network_security_group.nsg-hub.name
    resource_group_name         = var.resource_group.name
}






