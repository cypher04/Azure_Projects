# output "subnet_ids" {
#     description = "The IDs of the subnets in the virtual network"
#     value       = azurerm_subnet.main.id/ azurerm_subnet.app.id/ azurerm_subnet.database.id
# }


output "network_security_group_id" {
    description = "The ID of the Network Security Group"
    value       = azurerm_network_security_group.nsg.id
}


# output "network_security_group_resource_group_name" {
#     description = "The resource group name of the Network Security Group"
#     value       = azurerm_network_security_group.
# }

# output "security_rules" {
#     description = "The security rules of the Network Security Group"
#     value       = azurerm_network_security_group.main.security_rule
# }

# output "subnet_network_security_group_association_ids" {
#     description = "The IDs of the subnet and network security group associations"
#     value       = azurerm_subnet_network_security
# }
