output "resource_group_name" {
  value = azurerm_resource_group.rg-main.name
}
    
output "location" {
  value = azurerm_resource_group.rg-main.location
}

output "tags" {
  value = azurerm_resource_group.rg-main.tags
}



output "virtual_machine_scale_set_id" {
  value = module.compute.virtual_machine_scale_set_id
}