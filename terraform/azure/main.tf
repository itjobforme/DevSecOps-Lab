provider "azurerm" {
  features {}
  use_oidc = true
}

resource "azurerm_resource_group" "devsecops_rg" {
  name     = "devsecops-lab-rg"
  location = "East US"
}


