# main.tf
# This file contains the primary resource definitions for the VM module.

# Creates a public IP address for each VM where public_ip_required is true.
resource "azurerm_public_ip" "vm_public_ip" {
  for_each = { for k, v in var.vm_definitions : k => v if v.public_ip_required }

  name                = "pip-VM-${each.value.vm_type}-${var.location}-${each.value.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static" # Using Static for predictable IPs

  tags = merge(var.default_tags, each.value.additional_tags)
}

# Creates a network interface (NIC) for each VM.
resource "azurerm_network_interface" "vm_nic" {
  for_each = var.vm_definitions

  name                = "nic-VM-${each.value.vm_type}-${var.location}-${each.value.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name


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
  for_each = var.vm_definitions

  # VM Name Generation: VM-<VMType>-<Location>-<NameSuffix>
  name                = "VM-${each.value.vm_type}-${var.location}-${each.value.name_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = each.value.sku # Use 'sku' for VM size
  admin_username      = each.value.admin_username
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.vm_nic[each.key].id]

  # OS Disk Configuration from vm_definitions
  os_disk {
    caching              = "ReadWrite" # Common setting for OS disk
    storage_account_type = each.value.os_disk_type
    disk_size_gb         = each.value.os_disk_size_gb
    name                 = "${each.value.name_suffix}-osdisk" # OS disk named after VM suffix
  }

  # Source Image Reference from vm_definitions
  source_image_reference {
    publisher = each.value.source_image_publisher
    offer     = each.value.source_image_offer
    sku       = each.value.source_image_sku
    version   = each.value.source_image_version
  }

  # SSH Public Key for authentication.
  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.ssh_public_key
  }

  tags = merge(var.default_tags, each.value.additional_tags)
}

# Creates managed disks for data disks.
resource "azurerm_managed_disk" "data_disk" {
  # This flattens the vm_definitions to create a unique key for each data disk across all VMs.
  # The 'for' loop for 'disk' needs to be *within* the context of the outer 'for' loop's value generation.
  for_each = {
    for vm_key, vm_def in var.vm_definitions :
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
    for vm_key, vm_def in var.vm_definitions : [
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



