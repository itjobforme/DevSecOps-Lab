provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "devsecops_rg" {
  name     = "devsecops-lab-rg"
  location = "East US"
}

module "aks" {
  source = "./aks"
  resource_group_name = azurerm_resource_group.devsecops_rg.name
  location            = azurerm_resource_group.devsecops_rg.location
}
