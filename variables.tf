variable "notification_email" {
  description = "Email address to receive secret expiration notifications"
  type        = string
}

variable "days_before_expiry" {
  description = "Number of days before expiration to trigger notification"
  type        = number
  default     = 30
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "uksouth"
}

variable "logic_app_name" {
  description = "Name of the Logic App for secret monitoring"
  type        = string
  default     = "logic-secret-expiry-monitor"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-secret-monitor"
}

variable "key_vault_name" {
  description = "Name of the existing Key Vault to store rotated secrets"
  type        = string
}

variable "key_vault_resource_group" {
  description = "Resource group containing the existing Key Vault"
  type        = string
  default     = "rg-platform"
}
