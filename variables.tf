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
  default = local.common_tags

}

# --- VM Specific Inputs (Each attribute is a separate list, correlated by index via vm_name_suffixes) ---
# NOTE: The length and order of these lists MUST match the vm_name_suffixes list.

variable "vm_name_suffixes" {
  description = "A list of unique suffixes for each VM name (e.g., ['web-01', 'app-01', 'db-01']). These will be the keys for internal correlation."
  type        = list(string)
}

variable "vm_types" {
  description = "A list of VM types for naming (e.g., ['Web', 'App', 'SQL']), corresponding to vm_name_suffixes."
  type        = list(string)
}

variable "vm_skus" {
  description = "A list of VM sizes (e.g., ['Standard_B1s', 'Standard_D2s_v3']), corresponding to vm_name_suffixes."
  type        = list(string)
}

# RE-ADDED: Placeholder for admin_username
variable "vm_admin_username_placeholder" {
  description = "A placeholder administrator username required by AzureRM provider, even when using AAD Login. This user is not intended for direct access."
  type        = string
  default     = "azureuser" # Common default placeholder
}

# RE-ADDED: Placeholder for ssh_public_key
variable "vm_ssh_public_key_placeholder" {
  description = "A placeholder SSH public key required by AzureRM provider, even when using AAD Login. This key is not intended for direct access."
  type        = string
  # IMPORTANT: Replace with a valid (but non-critical) public key.
  # This can be a dummy key that won't actually be used, or a key for a highly restricted, internal account.
  # For example, you can generate one with `ssh-keygen -t rsa -b 4096 -f ~/.ssh/placeholder_azure_key`
  # and then paste the content of `placeholder_azure_key.pub` here.
  # Example: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3b2..."
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD4sS7i2lR7gN9h... placeholder_key_for_aad_vms"
}

variable "vm_subnet_ids" {
  description = "A list of subnet IDs to connect each VM to, corresponding to vm_name_suffixes."
  type        = list(string)
}

variable "vm_public_ip_required" {
  description = "A list of booleans indicating if a public IP is needed for each VM, corresponding to vm_name_suffixes."
  type        = list(bool)
}

variable "vm_os_disk_sizes_gb" {
  description = "A list of OS disk sizes in GB for each VM, corresponding to vm_name_suffixes."
  type        = list(number)
}

variable "vm_os_disk_types" {
  description = "A list of OS disk types (e.g., 'Standard_LRS', 'Premium_LRS') for each VM, corresponding to vm_name_suffixes."
  type        = list(string)
}

# --- Source Image Configuration (per VM, correlated by index) ---
variable "vm_source_image_publishers" {
  description = "A list of publishers for each VM image, corresponding to vm_name_suffixes."
  type        = list(string)
}

variable "vm_source_image_offers" {
  description = "A list of offers for each VM image, corresponding to vm_name_suffixes."
  type        = list(string)
}

variable "vm_source_image_skus" {
  description = "A list of SKUs for each VM image, corresponding to vm_name_suffixes."
  type        = list(string)
}

variable "vm_source_image_versions" {
  description = "A list of versions for each VM image, corresponding to vm_name_suffixes."
  type        = list(string)
}

variable "vm_additional_tags" {
  description = "A list of maps of additional tags for each VM, to merge with default_tags. Corresponds to vm_name_suffixes."
  type        = list(map(string))
  default     = [] # Default to empty maps if no additional tags for specific VMs.
}

variable "vm_nsg_ids" {
  description = "A list of optional NSG IDs for each VM, corresponding to vm_name_suffixes. Use 'null' for no NSG."
  type        = list(string) # 'string' type allows 'null' values when explicitly provided.
  default     = [] # Default to empty list. If a VM doesn't need an NSG, its position should be 'null'.
}

# --- ONLY Data Disks Variable (map of lists of objects) ---
variable "vm_data_disks_map" {
  description = "A map where keys are VM name_suffixes and values are lists of data disk objects for that VM."
  type = map(list(object({
    size_gb            = number # Size of the data disk in GB.
    lun                = number # Logical Unit Number for the data disk (must be unique per VM).
    storage_account_type = string # Type of the data disk.
    caching            = string # Caching method for the disk (e.g., "ReadWrite", "ReadOnly", "None").
  })))
  default = {} # Default to an empty map if no data disks are specified for any VM
}

# --- NEW: Single AAD Group for Access to ALL VMs ---
variable "aad_group_for_vm_access" {
  description = "The Object ID of the single Azure AD Group that will have 'Virtual Machine Administrator Login' access to all created VMs. Set to null if no AAD group access is desired."
  type        = string
  default     = null # Default to null, meaning no AAD group access by default.
}

# variable "vm_definitions" {
#   description = "A map of objects defining the configuration for each virtual machine to be created."
#   type = map(object({
#     name_suffix        = string  # Unique suffix for the VM name (e.g., "01", "web")
#     vm_type            = string  # Type of VM for naming (e.g., "App", "Web", "SQL")
#     sku                = string  # VM size (e.g., Standard_B1s, Standard_D2s_v3). No default.
#     admin_username     = string  # Administrator username for the VM. No default.
#     ssh_public_key     = string  # SSH public key for Linux VM authentication. No default.
#     subnet_id          = string  # ID of the subnet to connect the VM to. No default.
#     public_ip_required = bool    # Set to true if a public IP is needed for the VM. No default.

#     # OS Disk Configuration (No defaults)
#     os_disk_size_gb    = number
#     os_disk_type       = string  # e.g., "Standard_LRS", "Premium_LRS"

#     # Source Image Configuration (No defaults)
#     source_image_publisher = string # e.g., "Canonical"
#     source_image_offer     = string # e.g., "UbuntuServer"
#     source_image_sku       = string # e.g., "20.04-LTS"
#     source_image_version   = string # e.g., "latest" or a specific version

#     # Data Disks Configuration (No defaults)
#     data_disks = list(object({
#       size_gb            = number # Size of the data disk in GB.
#       lun                = number # Logical Unit Number for the data disk (must be unique per VM).
#       storage_account_type = string # Type of the data disk.
#       caching            = string # Caching method for the disk (e.g., "ReadWrite", "ReadOnly", "None").
#     }))

#     # Additional tags to merge with default_tags
#     additional_tags    = optional(map(string), {}) # Optional, defaults to an empty map if not provided
#     nsg_id             = optional(string, null)    # Optional NSG ID, defaults to null (no NSG)
#   }))
# }