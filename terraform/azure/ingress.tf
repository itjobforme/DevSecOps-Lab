resource "azurerm_public_ip" "ingress_ip" {
  name                = "devsecops-ingress-ip"
  resource_group_name = data.azurerm_resource_group.devsecops_rg.name
  location            = data.azurerm_resource_group.devsecops_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

output "ingress_ip" {
  value = azurerm_public_ip.ingress_ip.ip_address
}
