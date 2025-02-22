# Create a Storage Account for Terraform State
resource "azurerm_storage_account" "tfstate" {
  name                     = "devsecopsterraform"
  resource_group_name      = azurerm_resource_group.devsecops_rg.name
  location                 = azurerm_resource_group.devsecops_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_blob_public_access = false

  lifecycle {
    prevent_destroy = true
  }
}

# Create a Container for Terraform State Files
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
