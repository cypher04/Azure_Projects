resource "azurerm_linux_virtual_machine_scale_set" "lvmss" {
    name                = "${var.project_name}-${var.environment}-lvmss"
    location            = var.location
    resource_group_name = var.resource_group_name
    sku                 = "Standard_DS1_v2"
    instances           = 4
    admin_username      = var.administrator_login
    admin_password      = var.administrator_password
    disable_password_authentication = false
    identity {
        type = "SystemAssigned"
    }

    admin_ssh_key {
        username   = var.administrator_login
        public_key = file(var.ssh_public_key_path)
    }
    
    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

custom_data = base64encode(file("${path.module}/../../scripts/cloud-init.yaml"))
    
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    
    network_interface {
        name    = "${var.project_name}-${var.environment}-nic"
        primary = true
    
        ip_configuration {
        name      = "${var.project_name}-${var.environment}-ipconfig"
        subnet_id = element(var.subnet_ids, 0)
        primary   = true
        load_balancer_backend_address_pool_ids = [var.load_balancer_backend_address_pool_id]
        }
    }
    
    
    tags = var.tags
}


resource "azurerm_ssh_public_key" "ssh_key" {
    name                = "${var.project_name}-${var.environment}-sshkey"
    location            = var.location
    resource_group_name = var.resource_group_name
    public_key          = file(var.ssh_public_key_path)
  
}