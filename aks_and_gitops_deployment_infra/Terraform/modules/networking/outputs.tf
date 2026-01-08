output "del_sub_id" {
  value = azurerm_subnet.app.id
}

output "acr_sub_id" {
  value = azurerm_subnet.acr_sub.id
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "web_sub_id" {
  value = azurerm_subnet.web.id
}

