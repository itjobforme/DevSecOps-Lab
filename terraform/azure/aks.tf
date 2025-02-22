resource "azurerm_kubernetes_cluster" "aks" {
  name                = "devsecops-aks"
  location            = data.azurerm_resource_group.devsecops_rg.location
  resource_group_name = data.azurerm_resource_group.devsecops_rg.name
  dns_prefix          = "devsecops-k8s"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}
