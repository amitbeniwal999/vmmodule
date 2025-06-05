# versions.tf

terraform {
  required_version = ">= 1.0.0" # Use a version compatible with your module and TFC

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Use a version compatible with your module
    }
  }
}

provider "azurerm" {
  features {} # Required for Azurerm provider ~>3.0
}