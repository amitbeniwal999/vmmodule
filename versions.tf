# versions.tf
terraform {
  required_version = ">= 1.0.0" # Specify your Terraform version
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Specify your AzureRM provider version
    }
  }
}