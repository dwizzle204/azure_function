output "resource_group_name" {
  description = "Resource group name."
  value       = azurerm_resource_group.this.name
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
