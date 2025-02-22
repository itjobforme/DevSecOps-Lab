terraform {
  backend "azurerm" {
    resource_group_name   = "devsecops-lab-rg"     
    storage_account_name  = "devsecopsterraform1" #created  
    container_name        = "tfstate"             #created
    key                   = "terraform.tfstate"     
  }
}
