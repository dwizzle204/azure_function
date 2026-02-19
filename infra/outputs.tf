output "resource_group_name" {
  description = "Resource group name."
  value       = data.azurerm_resource_group.this.name
}

output "function_app_name" {
  description = "Primary Function App name."
  value       = module.function_app_pattern.name
}

output "function_app_id" {
  description = "Primary Function App ID."
  value       = module.function_app_pattern.resource_id
}

output "function_app_default_hostname" {
  description = "Primary Function App default hostname."
  value       = try(module.function_app_pattern.resource.default_hostname, null)
}

output "storage_account_name" {
  description = "Storage account backing the Function App."
  value       = try(module.function_app_pattern.storage_account_resource.name, null)
}

output "vnet_integration_enabled" {
  description = "Whether Function App VNet integration is enabled."
  value       = var.enable_vnet_integration
}

output "key_vault_name" {
  description = "Key Vault name when enabled."
  value       = try(module.key_vault[0].name, null)
}

output "key_vault_uri" {
  description = "Key Vault URI when enabled."
  value       = try(module.key_vault[0].uri, null)
}

output "key_vault_private_endpoint_id" {
  description = "Key Vault private endpoint ID when enabled."
  value       = try(module.key_vault[0].private_endpoints.primary.id, null)
}
