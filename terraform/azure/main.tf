provider "azurerm" {
  features {}
  use_oidc = true
}
#
data "azurerm_resource_group" "devsecops_rg" {
  name = "devsecops-lab-rg"
}
