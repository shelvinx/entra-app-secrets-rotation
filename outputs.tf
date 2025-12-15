# Output the Logic App identity info
output "logic_app_identity_principal_id" {
  description = "Principal ID of the Logic App's managed identity"
  value       = azapi_resource.logic_app_secret_monitor.identity[0].principal_id
}

output "logic_app_resource_id" {
  description = "Resource ID of the Logic App"
  value       = azapi_resource.logic_app_secret_monitor.id
}

output "logic_app_portal_url" {
  description = "URL to view the Logic App in Azure Portal"
  value       = "https://portal.azure.com/#resource${azapi_resource.logic_app_secret_monitor.id}/logicApp"
}

output "how_to_test" {
  description = "Instructions for testing the Logic App"
  value       = "Go to Azure Portal > Logic Apps > ${var.logic_app_name} > Run Trigger > Daily_Check. Then check 'Runs history' to see results."
}

output "key_vault_uri" {
  description = "URI of the Key Vault storing rotated secrets"
  value       = data.azurerm_key_vault.secret_store.vault_uri
}
