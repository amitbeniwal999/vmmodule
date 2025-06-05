locals {
  common_tags = {
    Environment         = "dev"
    Project             = "MyWebApp"
    ManagedBy           = "Terraform"
    owner               = "Amit Beniwal"
    company             = "CloudZenLabs"
    location            = var.location
    project             = "CloudZenLabs-infra-setup"
    resource_group      = var.resource_group_name
  }

    vm_configs = {
    for i, name_suffix in var.vm_name_suffixes :
    name_suffix => {
      # Core VM attributes
      vm_type            = var.vm_types[i]
      sku                = var.vm_skus[i]
      # REMOVED: admin_username and ssh_public_key are no longer part of vm_configs
      subnet_id          = var.vm_subnet_ids[i]
      public_ip_required = var.vm_public_ip_required[i]
      os_disk_size_gb    = var.vm_os_disk_sizes_gb[i]
      os_disk_type       = var.vm_os_disk_types[i]
      source_image_publisher = var.vm_source_image_publishers[i]
      source_image_offer     = var.vm_source_image_offers[i]
      source_image_sku       = var.vm_source_image_skus[i]
      source_image_version   = var.vm_source_image_versions[i]

       # Placeholder admin credentials required by provider, even with AAD Login
      # These are NOT intended for direct login when AAD is configured.
      admin_username     = "azureuser" # Static placeholder username
      # IMPORTANT: Replace with a valid (but non-critical) public key.
      # Generate one with `ssh-keygen -t rsa -b 4096 -f ~/.ssh/placeholder_azure_key`
      # and paste the content of `placeholder_azure_key.pub` here.
      ssh_public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3b2... placeholder_key_for_aad_vms"


      # Optional attributes with default lookups
      additional_tags    = lookup(var.vm_additional_tags, i, {})
      nsg_id             = lookup(var.vm_nsg_ids, i, null)
    }
  }

}