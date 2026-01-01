resource "azurerm_linux_virtual_machine_scale_set" "lvmss" {
    name                = "${var.project_name}-${var.environment}-lvmss"
    location            = var.location
    resource_group_name = var.resource_group
    sku                 = "Standard_DS1_v2"
    instances           = 2
    admin_username      = var.administrator_login
    admin_password      = var.administrator_password
    disable_password_authentication = false
    
    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

custom_data = filebase64sha256("../scripts/cloud-init.yaml")
    
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
        }
    }
    
    tags = var.tags
}

