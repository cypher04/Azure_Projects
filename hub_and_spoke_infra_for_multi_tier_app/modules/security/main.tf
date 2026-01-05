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


// Application Gateway with WAF

resource "azurerm_application_gateway" "appgw" {
    name                = "${var.project_name}-appgw-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group
    identity {
        type = "SystemAssigned"
    }

    sku {
        name     = "WAF_v2"
        tier     = "WAF_v2"
    }

    autoscale_configuration {
      min_capacity = 2
      max_capacity = 5
    }

    gateway_ip_configuration {
        name      = "appgw-ip-config"
        subnet_id = [var.subnet_ids[0]]
    }

    frontend_port {
        name = "frontendPort"
        port = 80
    }

    frontend_ip_configuration {
        name                 = "appgw-frontend-ip"
        public_ip_address_id = var.public_ip_id
    }

    backend_address_pool {
        name = "appgw-backend-pool"
    }

    backend_http_settings {
        name                  = "appgw-backend-https-settings"
        cookie_based_affinity = "Disabled"
        port                  = 443
        protocol              = "Https"
        pick_host_name_from_backend_address = false
        probe_name            = "appgw-health-probe"
    }

    http_listener {
        name                           = "appgw-http-listener"
        frontend_ip_configuration_name = "appgw-frontend-ip"
        frontend_port_name             = "frontendPort"
        protocol                       = "Https"
    }

    request_routing_rule {
        name                       = "appgw-routing-rule"
        rule_type                  = "Basic"
        http_listener_name         = "appgw-http-listener"
        backend_address_pool_name  = "appgw-backend-pool"
        backend_http_settings_name = "appgw-backend-http-settings"
    }

    probe {
        name                = "appgw-health-probe"
        protocol            = "Https"
        host                = "localhost"
        path                = "/"
        interval            = 30
        timeout             = 30
        unhealthy_threshold = 3
        pick_host_name_from_backend_http_settings = false
    }

}

resource "azurerm_web_application_firewall_policy" "webafw" {
    name                = "${var.project_name}-waf-policy-${var.environment}"
    location            = var.location
    resource_group_name = var.resource_group

    custom_rules {
        name      = "BlockBadBots"
        priority  = 1
        rule_type = "MatchRule"

        match_conditions {
            match_variables {
                variable_name = "RemoteAddr"
                selector      = "RemoteAddr"
            }
            operator           = "Contains"
            match_values       = ["BadBot"]
            negation_condition = false
            transforms         = []
        }

        action = "Block"
    }

    policy_settings {
      enabled = true
      mode = "Prevention"
      request_body_check = true
     file_upload_limit_in_mb = 100
     max_request_body_size_in_kb = 128
    }

    managed_rules {
        managed_rule_set {
            type    = "OWASP"
            version = "3.2"
        }
    }
  
}





