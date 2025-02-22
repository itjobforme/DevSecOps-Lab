terraform {
  backend "azurerm" {
    resource_group_name   = "devsecops-lab-rg"     
    storage_account_name  = "devsecopsterraform"   
    container_name        = "tfstate"             
    key                   = "terraform.tfstate"

    # Service Principal Authentication for Backend
    tenant_id       = var.tenant_id
    client_id       = var.client_id
    client_secret   = var.client_secret
    subscription_id = var.subscription_id
  }
}
