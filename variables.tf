# variables.tf
# Defines the input variables for the VM module.

variable "resource_group_name" {
  description = "The name of the Azure Resource Group where the VMs and associated resources will be created."
  type        = string
}

variable "location" {
  description = "The Azure region where the VMs and associated resources will be deployed. Used in VM naming."
  type        = string
}

variable "default_tags" {
  description = "A map of default tags to apply to all resources created by this module."
  type        = map(string)
  default = { # These are the ONLY default values allowed in the module itself, as requested
    "ManagedBy" = "Terraform"
    "CreatedBy" = "TFModule"
  }
}

variable "vm_definitions" {
  description = "A map of objects defining the configuration for each virtual machine to be created."
  type = map(object({
    name_suffix        = string  # Unique suffix for the VM name (e.g., "01", "web")
    vm_type            = string  # Type of VM for naming (e.g., "App", "Web", "SQL")
    sku                = string  # VM size (e.g., Standard_B1s, Standard_D2s_v3). No default.
    admin_username     = string  # Administrator username for the VM. No default.
    ssh_public_key     = string  # SSH public key for Linux VM authentication. No default.
    subnet_id          = string  # ID of the subnet to connect the VM to. No default.
    public_ip_required = bool    # Set to true if a public IP is needed for the VM. No default.

    # OS Disk Configuration (No defaults)
    os_disk_size_gb    = number
    os_disk_type       = string  # e.g., "Standard_LRS", "Premium_LRS"

    # Source Image Configuration (No defaults)
    source_image_publisher = string # e.g., "Canonical"
    source_image_offer     = string # e.g., "UbuntuServer"
    source_image_sku       = string # e.g., "20.04-LTS"
    source_image_version   = string # e.g., "latest" or a specific version

    # Data Disks Configuration (No defaults)
    data_disks = list(object({
      size_gb            = number # Size of the data disk in GB.
      lun                = number # Logical Unit Number for the data disk (must be unique per VM).
      storage_account_type = string # Type of the data disk.
      caching            = string # Caching method for the disk (e.g., "ReadWrite", "ReadOnly", "None").
    }))

    # Additional tags to merge with default_tags
    additional_tags    = optional(map(string), {}) # Optional, defaults to an empty map if not provided
    nsg_id             = optional(string, null)    # Optional NSG ID, defaults to null (no NSG)
  }))
}