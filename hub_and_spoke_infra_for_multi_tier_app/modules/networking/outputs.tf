output "subnet_ids" {
    value = azurerm_subnet.*.id
}

output "virtual_network_id" {
    value = azurerm_virtual_network.vnet-spoke-1.id
}

output "virtual_network_id_spoke_2" {
    value = azurerm_virtual_network.vnet-spoke-2.id
}

output "virtual_network_peering_ids" {
    value = [
        azurerm_virtual_network_peering.hub-to-spoke1.id,
        azurerm_virtual_network_peering.spoke1-to-hub.id,
        azurerm_virtual_network_peering.hub-to-spoke2.id,
        azurerm_virtual_network_peering.spoke2-to-hub.id
    ]
}

output "subnet_id_spoke_1_web" {
    value = azurerm_subnet.subnet-spoke-1-web.id
}

output "subnet_id_spoke_2_app" {
    value = azurerm_subnet.subnet-spoke-2-app.id
}

output "virtual_network_name_spoke_1" {
    value = azurerm_virtual_network.vnet-spoke-1.name
}

output "virtual_network_name_spoke_2" {
    value = azurerm_virtual_network.vnet-spoke-2.name
}

