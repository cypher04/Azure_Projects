output "subnet_ids" {
  value = var.subnet_ids
}

output "virtual_machine_scale_set_id" {
  value = azurerm_linux_virtual_machine_scale_set.lvmss.id
}



