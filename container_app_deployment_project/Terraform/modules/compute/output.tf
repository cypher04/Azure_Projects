output "acr_id" {
    value = azurerm_container_registry.acr.id
}

output "aca_name" {
    value = azurerm_container_app.aca.name
}

output "app_url" {
    value = azurerm_container_app.aca.ingress[0].fqdn
}