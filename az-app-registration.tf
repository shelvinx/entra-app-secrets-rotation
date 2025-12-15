data "azuread_client_config" "current" {}

# Create a sample app registration in Entra
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
