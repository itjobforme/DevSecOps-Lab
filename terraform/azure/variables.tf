variable "tenant_id" {
  description = "Azure Tenant ID"
}

variable "client_id" {
  description = "Azure Client ID"
}

variable "client_secret" {
  description = "Azure Client Secret"
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure Subscription ID"
}
