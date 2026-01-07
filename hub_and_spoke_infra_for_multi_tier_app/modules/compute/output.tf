output "linux_web_app_id" {
    value = azurerm_linux_web_app.web_app.id
}

output "app_service_id" {
    value = azurerm_linux_web_app.web_app.id
}

output "cosmosdb_private_dns_zone_id" {
    value = azurerm_private_dns_zone.pdz-cosmosdb.id
}

output "webapp_private_dns_zone_id" {
    value = azurerm_private_dns_zone.pdz-webapp.id
}