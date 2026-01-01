output "subnet_ids" {
    value = azurerm_subnet.subnet.*.id
}

output "private_ip_addresses" {
    value = azurerm_network_interface.nic.*.private_ip_address
  
}

output "virtual_network_id" {
    value = azurerm_virtual_network.vnet.id
}

