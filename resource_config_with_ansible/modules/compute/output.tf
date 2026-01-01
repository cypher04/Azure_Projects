output "subnet_ids" {
  value = var.subnet_ids
}

output "virtual_machine_ids" {
  value = azurerm_linux_virtual_machine.vm.*.id
}

output "virtual_machine_private_ip_addresses" {
  value = azurerm_linux_virtual_machine.vm.*.private_ip_address
}

output "virtual_machine_scale_set_id" {
  value = azurerm_linux_virtual_machine_scale_set.lvmss.id
}

