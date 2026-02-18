terraform {
  required_version = ">= 1.6.0"

  cloud {
    organization = "replace-with-tfc-organization"

    workspaces {
      tags = ["azure-function"]
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}
