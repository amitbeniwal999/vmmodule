# main.tf
# This file contains the primary resource definitions for the VM module.

# Creates a public IP address for each VM where public_ip_required is true.
resource "azurerm_public_ip" "vm_public_ip" {
  for_each = { for k, v in local.vm_configs : k => v if v.public_ip_required }

  name                = "pip-VM-${each.value.vm_type}-${var.location}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"

  tags = merge(var.default_tags, each.value.additional_tags)
}

# Creates a network interface (NIC) for each VM.
resource "azurerm_network_interface" "vm_nic" {
  for_each = local.vm_configs

  name                = "nic-VM-${each.value.vm_type}-${var.location}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
#   network_security_group_id = each.value.nsg_id

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.public_ip_required ? azurerm_public_ip.vm_public_ip[each.key].id : null
  }

  tags = merge(var.default_tags, each.value.additional_tags)
}

# Creates a Linux Virtual Machine for each definition.
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = local.vm_configs
  name                = "VM-${each.value.vm_type}-${var.location}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = each.value.sku
  # Use placeholder admin credentials from locals
  admin_username = each.value.admin_username
  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.ssh_public_key
  }
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.vm_nic[each.key].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_sizes_gb
    name                 = "${each.key}-osdisk"
  }

  source_image_reference {
    publisher = each.value.source_image_publisher
    offer     = each.value.source_image_offer
    sku       = each.value.source_image_sku
    version   = each.value.source_image_version
  }

  # REMOVED: admin_ssh_key block is no longer needed for AAD login

  tags = merge(var.default_tags, each.value.additional_tags)
}

# NEW: Install Azure AD Login for Linux extension on all VMs that are configured.
resource "azurerm_virtual_machine_extension" "aad_login_extension" {
  # Install extension if aad_group_for_vm_access is provided
  for_each = var.aad_group_for_vm_access != null ? azurerm_linux_virtual_machine.vm : {}

  name                 = "AADLoginForLinux"
  virtual_machine_id   = each.value.id # Use each.value.id from the azurerm_linux_virtual_machine.vm map
  publisher            = "Microsoft.Azure.ActiveDirectory.LinuxSSH"
  type                 = "AADLoginForLinux"
  type_handler_version = "1.0"
  auto_upgrade_minor_version = true

  tags = merge(var.default_tags, local.vm_configs[each.key].additional_tags) # Use tags from local.vm_configs based on the key
}

# NEW: Assign RBAC role for the single AAD group to each VM
resource "azurerm_role_assignment" "aad_vm_admin_access" {
  # Assign role if aad_group_for_vm_access is provided
  for_each = var.aad_group_for_vm_access != null ? azurerm_linux_virtual_machine.vm : {}

  scope                = each.value.id # Scope to the individual VM
  role_definition_name = "Virtual Machine Administrator Login" # Granting admin access
  principal_id         = var.aad_group_for_vm_access
  description          = "Granting Virtual Machine Administrator Login to AAD Group ${var.aad_group_for_vm_access} for VM ${each.value.name}"

  # Ensure the extension is applied before role assignment, although Terraform usually handles implicit dependencies
  depends_on = [azurerm_virtual_machine_extension.aad_login_extension]
}

# # Creates managed disks for data disks.
# resource "azurerm_managed_disk" "data_disk" {
#   for_each = {
#     for vm_key, vm_config in local.vm_configs :
#     "${vm_key}-${disk.lun}" => {
#       disk_name            = "${vm_key}-${disk.lun}-data-disk"
#       resource_group_name  = var.resource_group_name
#       location             = var.location
#       storage_account_type = disk.storage_account_type
#       create_option        = "Empty"
#       disk_size_gb         = disk.size_gb
#       tags                 = merge(var.default_tags, vm_config.additional_tags)
#       caching              = disk.caching
#     }
#     # FIXED: Correct 'for' expression syntax for nested loop
#     for disk in lookup(var.vm_data_disks_map, vm_key, [])
#   }

#   name                 = each.value.disk_name
#   location             = each.value.location
#   resource_group_name  = each.value.resource_group_name
#   storage_account_type = each.value.storage_account_type
#   create_option        = each.value.create_option
#   disk_size_gb         = each.value.disk_size_gb
#   tags                 = each.value.tags
# }

# # Attaches data disks to each VM.
# resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
#   for_each = {
#     for vm_key, vm_config in local.vm_configs : # Iterate over consolidated VM configs
#     "${vm_key}-${disk.lun}" => {
#       vm_id  = azurerm_linux_virtual_machine.vm[vm_key].id
#       disk   = disk
#     }
#     # Lookup the list of data disks for the current vm_key. Defaults to empty list if no entry.
#     for disk in lookup(var.vm_data_disks_map, vm_key, [])
#   }

#   virtual_machine_id = each.value.vm_id
#   lun                = each.value.disk.lun
#   managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
#   caching            = each.value.disk.caching
# }

# # main.tf
# # This file contains the primary resource definitions for the VM module.

# # Creates a public IP address for each VM where public_ip_required is true.
# resource "azurerm_public_ip" "vm_public_ip" {
#   for_each = { for k, v in var.vm_definitions : k => v if v.public_ip_required }

#   name                = "pip-VM-${each.value.vm_type}-${var.location}-${each.value.name_suffix}"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   allocation_method   = "Static" # Using Static for predictable IPs

#   tags = merge(var.default_tags, each.value.additional_tags)
# }

# # Creates a network interface (NIC) for each VM.
# resource "azurerm_network_interface" "vm_nic" {
#   for_each = var.vm_definitions

#   name                = "nic-VM-${each.value.vm_type}-${var.location}-${each.value.name_suffix}"
#   location            = var.location
#   resource_group_name = var.resource_group_name


#   ip_configuration {
#     name                          = "ipconfig1"
#     subnet_id                     = each.value.subnet_id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = each.value.public_ip_required ? azurerm_public_ip.vm_public_ip[each.key].id : null
#   }

#   tags = merge(var.default_tags, each.value.additional_tags)
# }

# # Creates a Linux Virtual Machine for each definition.
# resource "azurerm_linux_virtual_machine" "vm" {
#   for_each = var.vm_definitions

#   # VM Name Generation: VM-<VMType>-<Location>-<NameSuffix>
#   name                = "VM-${each.value.vm_type}-${var.location}-${each.value.name_suffix}"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   size                = each.value.sku # Use 'sku' for VM size
#   admin_username      = each.value.admin_username
#   disable_password_authentication = true

#   network_interface_ids = [azurerm_network_interface.vm_nic[each.key].id]

#   # OS Disk Configuration from vm_definitions
#   os_disk {
#     caching              = "ReadWrite" # Common setting for OS disk
#     storage_account_type = each.value.os_disk_type
#     disk_size_gb         = each.value.os_disk_size_gb
#     name                 = "${each.value.name_suffix}-osdisk" # OS disk named after VM suffix
#   }

#   # Source Image Reference from vm_definitions
#   source_image_reference {
#     publisher = each.value.source_image_publisher
#     offer     = each.value.source_image_offer
#     sku       = each.value.source_image_sku
#     version   = each.value.source_image_version
#   }

#   # SSH Public Key for authentication.
#   admin_ssh_key {
#     username   = each.value.admin_username
#     public_key = each.value.ssh_public_key
#   }

#   tags = merge(var.default_tags, each.value.additional_tags)
# }

# Creates managed disks for data disks.
resource "azurerm_managed_disk" "data_disk" {
  # This flattens the vm_definitions to create a unique key for each data disk across all VMs.
  # The 'for' loop for 'disk' needs to be *within* the context of the outer 'for' loop's value generation.
  for_each = {
    for vm_key, vm_def in local.vm_configs :
    # This creates the key-value pairs for the resulting map
    "${vm_key}-${disk.lun}" => {
      disk_name            = "${vm_key}-${disk.lun}-data-disk"
      resource_group_name  = var.resource_group_name
      location             = var.location
      storage_account_type = disk.storage_account_type
      create_option        = "Empty"
      disk_size_gb         = disk.size_gb
      tags                 = merge(var.default_tags, vm_def.additional_tags)
      caching              = disk.caching
    }
    # This is the inner 'for' loop, correctly placed after the value expression (the {...} block)
    # for disk in vm_def.data_disks
  }

  name                 = each.value.disk_name
  location             = each.value.location
  resource_group_name  = each.value.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.disk_size_gb
  tags                 = each.value.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  for_each = merge([
    for vm_key, vm_def in local.vm_configs : [
      for disk in vm_def.data_disks : {
        "${vm_key}-${disk.lun}" = {
          vm_id = azurerm_linux_virtual_machine.vm[vm_key].id
          disk  = disk
        }
      }
    ]
  ]...)

  virtual_machine_id = each.value.vm_id
  lun                = each.value.disk.lun
  managed_disk_id    = azurerm_managed_disk.data_disk[each.key].id
  caching            = each.value.disk.caching
}



