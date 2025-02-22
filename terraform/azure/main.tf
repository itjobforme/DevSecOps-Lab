provider "azurerm" {
  features {}

  # Use the default Azure CLI authentication (via OIDC)
  use_oidc = true
}

resource "azurerm_resource_group" "devsecops_rg" {
  name     = "devsecops-lab-rg"
  location = "East US"
}
