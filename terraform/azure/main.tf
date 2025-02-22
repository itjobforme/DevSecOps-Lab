provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "devsecops_rg" {
  name     = "devsecops-lab-rg"
  location = "East US"
}

# Azure Resource Group
resource "azurerm_resource_group" "devsecops_rg" {
  name     = "devsecops-lab-rg"
  location = "East US"
}

# Storage Account for Terraform State
resource "azurerm_storage_account" "tfstate" {
  name                     = "devsecopsterraform"
  resource_group_name      = azurerm_resource_group.devsecops_rg.name
  location                 = azurerm_resource_group.devsecops_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "devsecops"
  }
}

# Blob Container for State Files
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}


module "aks" {
  source = "./aks"
  resource_group_name = azurerm_resource_group.devsecops_rg.name
  location            = azurerm_resource_group.devsecops_rg.location
}
