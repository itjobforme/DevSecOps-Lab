resource "azurerm_public_ip" "ingress_ip" {
  name                = "devsecops-ingress-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

output "ingress_ip" {
  value = azurerm_public_ip.ingress_ip.ip_address
}
