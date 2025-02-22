terraform {
  backend "azurerm" {
    resource_group_name   = "devsecops-lab-rg"     
    storage_account_name  = "devsecopsterraform"   
    container_name        = "tfstate"             
    key                   = "terraform.tfstate"     
  }
}
