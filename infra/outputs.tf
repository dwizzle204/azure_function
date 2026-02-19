output "resource_group_name" {
  description = "Resource group name."
  value       = data.azurerm_resource_group.this.name
}

output "function_app_name" {
  description = "Primary Function App name."
  value       = azurerm_linux_function_app.this.name
}

output "function_app_id" {
  description = "Primary Function App ID."
  value       = azurerm_linux_function_app.this.id
}

output "function_app_default_hostname" {
  description = "Primary Function App default hostname."
  value       = azurerm_linux_function_app.this.default_hostname
}

output "stage_slot_id" {
  description = "Stage deployment slot ID when stage slot is enabled."
  value       = try(azurerm_linux_function_app_slot.stage[0].id, null)
}

output "storage_account_name" {
  description = "Storage account backing the Function App."
  value       = azurerm_storage_account.this.name
}

output "key_vault_name" {
  description = "Key Vault name when enabled."
  value       = try(azurerm_key_vault.this[0].name, null)
}

output "key_vault_uri" {
  description = "Key Vault URI when enabled."
  value       = try(azurerm_key_vault.this[0].vault_uri, null)
}

output "vnet_integration_enabled" {
  description = "Whether Function App VNet integration is enabled."
  value       = var.enable_vnet_integration
}

output "storage_private_endpoint_id" {
  description = "Storage blob private endpoint ID when enabled."
  value       = try(azurerm_private_endpoint.storage_blob[0].id, null)
}

output "key_vault_private_endpoint_id" {
  description = "Key Vault private endpoint ID when enabled."
  value       = try(azurerm_private_endpoint.key_vault[0].id, null)
}

output "function_app_private_endpoint_id" {
  description = "Function App private endpoint ID when enabled."
  value       = try(azurerm_private_endpoint.function_app[0].id, null)
}
