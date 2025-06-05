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
}