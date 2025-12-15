
resource "time_rotating" "six_months_rotation" {
  rotation_days = 180
}

resource "azuread_application" "test_app" {
  display_name = "test-app"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "test_app" {
  client_id = azuread_application.test_app.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "test_app" {
  application_id = azuread_application.test_app.id
  display_name   = "client-secret"
  rotate_when_changed = {
    rotation = time_rotating.six_months_rotation.id
  }

  end_date = timeadd(time_rotating.six_months_rotation.rotation_rfc3339, "744h")

  lifecycle {
    create_before_destroy = true
  }
}

data "azuread_client_config" "current" {}

# =============================================================================
# SECRET EXPIRATION MONITORING - Logic App (Test Version - No Email)
# =============================================================================

# Resource Group for monitoring resources
resource "azurerm_resource_group" "secret_monitor" {
  name     = var.resource_group_name
  location = var.location
}

# Get current subscription
data "azurerm_subscription" "current" {}

# Logic App Workflow using AzAPI for full workflow definition support
# Workflow definition is loaded from external JSON template file
resource "azapi_resource" "logic_app_secret_monitor" {
  type      = "Microsoft.Logic/workflows@2019-05-01"
  name      = var.logic_app_name
  location  = azurerm_resource_group.secret_monitor.location
  parent_id = azurerm_resource_group.secret_monitor.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      state = "Enabled"
      definition = jsondecode(templatefile("${path.module}/logic-app-workflow.json", {
        email_template_html = jsonencode(file("${path.module}/email-template.html"))
      })).definition
      parameters = {
        daysBeforeExpiry = {
          value = var.days_before_expiry
        }
        keyVaultUri = {
          value = data.azurerm_key_vault.secret_store.vault_uri
        }
        notificationEmail = {
          value = var.notification_email
        }
      }
    }
  }

  tags = {
    purpose = "secret-expiration-monitoring"
  }
}

# Microsoft Graph API Service Principal (for permission assignment)
data "azuread_service_principal" "msgraph" {
  client_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
}

# Grant Application.ReadWrite.All to Logic App's managed identity (needed for rotation)
resource "azuread_app_role_assignment" "logic_app_graph_permission" {
  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
  principal_object_id = azapi_resource.logic_app_secret_monitor.identity[0].principal_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

# =============================================================================
# KEY VAULT INTEGRATION - For storing rotated secrets
# =============================================================================

# Reference existing Key Vault
data "azurerm_key_vault" "secret_store" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

# Grant Logic App managed identity "Key Vault Secrets Officer" role
resource "azurerm_role_assignment" "logic_app_kv_secrets" {
  scope                = data.azurerm_key_vault.secret_store.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azapi_resource.logic_app_secret_monitor.identity[0].principal_id
}

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
