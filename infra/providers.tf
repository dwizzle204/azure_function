terraform {
  required_version = ">= 1.10.0"

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
  }
}

provider "azurerm" {
  features {}
}
