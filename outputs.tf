# outputs.tf
# Defines the output values from the VM module.

output "vm_names" {
  description = "A map of the dynamically generated VM names, keyed by their definition name_suffix."
  value       = { for k, vm in azurerm_linux_virtual_machine.vm : k => vm.name }
}

output "vm_private_ips" {
  description = "A map of private IP addresses for the created virtual machines, keyed by their definition name_suffix."
  value       = { for k, nic in azurerm_network_interface.vm_nic : k => nic.private_ip_address }
}

output "vm_public_ips" {
  description = "A map of public IP addresses for VMs with public IPs, keyed by their definition name_suffix."
  value       = { for k, pip in azurerm_public_ip.vm_public_ip : k => pip.ip_address }
}

output "vm_network_interface_ids" {
  description = "A map of Network Interface IDs for the created virtual machines, keyed by their definition name_suffix."
  value       = { for k, nic in azurerm_network_interface.vm_nic : k => nic.id }
}

output "vm_ids" {
  description = "A map of Virtual Machine IDs for the created virtual machines, keyed by their definition name_suffix."
  value       = { for k, vm in azurerm_linux_virtual_machine.vm : k => vm.id }
}