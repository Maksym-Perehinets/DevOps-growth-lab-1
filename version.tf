terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.94.0 "
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tf-tfstate-ResourceGroup"
    storage_account_name = "tfstatestac3e7d7b3d"
    container_name       = "tf-tfstate-for-production"
    key                  = "prod.tfstate"
  }
}

provider "azurerm" {
  features {}
}
