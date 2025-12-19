output "app" {
    description = "The App Subnet ID"
    value       = azurerm_subnet.app.id
}

output "database" {
    description = "The Database Subnet ID"
    value       = azurerm_subnet.database.id
}

output "pip_id" {
    description = "The Public IP Address"
    value       = azurerm_public_ip.pip.id
}

output "main" {
    description = "The Management Subnet ID"
    value       = azurerm_subnet.main.id
}

output "subnet_ids" {    
    description = "The subnet ID where the compute resources are deployed"
    value       = [
        azurerm_subnet.app.id, azurerm_subnet.database.id, azurerm_subnet.main.id
        ]
    
}

output "public_ip" {
    description = "The Public IP Address"
    value       = azurerm_public_ip.pip
}

