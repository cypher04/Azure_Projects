output "subnet_ids" {
    value = azurerm_subnet.subnet.*.id
}

output "virtual_network_id" {
    value = azurerm_virtual_network.vnet.id
}


output "load_balancer_id" {
    value = azurerm_lb.lb.id
}

output "public_ip_id" {
    value = azurerm_public_ip.public_ip.id
}

output "load_balancer_backend_address_pool_id" {
    value = azurerm_lb_backend_address_pool.lbap.id
}