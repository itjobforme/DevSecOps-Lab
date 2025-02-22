provider "azurerm" {
  features {}

  # Use the default Azure CLI authentication (via OIDC)
  use_oidc = true
}

# Resource Group for the AKS Cluster
resource "azurerm_resource_group" "devsecops_rg" {
  name     = "devsecops-lab-rg"
  location = "East US"
}
