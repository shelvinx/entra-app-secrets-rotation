# Azure Entra ID Secret Rotation

Automated rotation of client secrets for Azure Entra ID application registrations using Azure Logic Apps.

## Features

- 🔄 Automatic rotation of expiring client secrets
- 🔐 Secure storage in Azure Key Vault
- 📧 Email notifications via Resend
- ⏰ Configurable expiry threshold (default: 30 days)

## Prerequisites

- [Terraform]
- Azure CLI authenticated (`az login`)
- An existing Azure Key Vault
- A [Resend](https://resend.com) API key stored in Key Vault as `api-key-resend`

## Configuration

Set the following environment variables before running Terraform:

```powershell
# PowerShell
$env:TF_VAR_notification_email = "your-email@example.com"
$env:TF_VAR_key_vault_name = "your-keyvault-name"
```

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TF_VAR_days_before_expiry` | `30` | Days before expiry to trigger rotation |
| `TF_VAR_location` | `uksouth` | Azure region |

## Deployment

```bash
terraform init
terraform plan
terraform apply
```

## How It Works

1. Logic App runs daily at 8:00 AM UTC
2. Queries Microsoft Graph for all app registrations
3. Identifies secrets expiring within the configured threshold
4. Creates new 180-day secrets for apps with only expiring secrets
5. Stores new secrets in Key Vault with metadata tags
6. Sends email notification with rotation details

## Required Permissions

TF Service Principal should be able to assigned the following permissions:
- **Microsoft Graph**: `Application.ReadWrite.All`
- **Key Vault**: `Key Vault Secrets Officer`
