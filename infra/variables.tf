variable "project_name" {
  description = "Short project identifier used in resource naming."
  type        = string
}

variable "resource_group_name" {
  description = "Pre-created resource group name from subscription bootstrap."
  type        = string
}

variable "app_service_plan_sku" {
  description = "App Service plan SKU for the Function App plan."
  type        = string
  default     = "Y1"
}

variable "python_version" {
  description = "Python runtime version for the Function App."
  type        = string
  default     = "3.11"
}

variable "functions_extension_version" {
  description = "Functions host runtime major version."
  type        = string
  default     = "~4"
}

variable "enable_stage_slot" {
  description = "Whether to create a stage slot for swap-based promotion."
  type        = bool
  default     = false
}

variable "stage_slot_name" {
  description = "Name of the stage slot used for production promotion."
  type        = string
  default     = "stage"
}

variable "enable_key_vault" {
  description = "Whether to create a Key Vault for this Function App environment."
  type        = bool
  default     = true
}

variable "key_vault_sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft delete retention window for Key Vault."
  type        = number
  default     = 90
}

variable "enable_vnet_integration" {
  description = "Whether to enable regional VNet integration for the Function App."
  type        = bool
  default     = false
}

variable "function_app_integration_subnet_id" {
  description = "Existing subnet ID used for Function App regional VNet integration when enabled."
  type        = string
  default     = null
}

variable "private_endpoint_subnet_id" {
  description = "Existing subnet ID used for private endpoints when any private endpoint is enabled."
  type        = string
  default     = null
}

variable "enable_storage_private_endpoint" {
  description = "Whether to create a private endpoint for the Storage Account (blob)."
  type        = bool
  default     = false
}

variable "storage_private_dns_zone_id" {
  description = "Private DNS zone ID for Storage private endpoint (privatelink.blob.core.windows.net)."
  type        = string
  default     = null
}

variable "enable_key_vault_private_endpoint" {
  description = "Whether to create a private endpoint for Key Vault."
  type        = bool
  default     = false
}

variable "key_vault_private_dns_zone_id" {
  description = "Private DNS zone ID for Key Vault private endpoint (privatelink.vaultcore.azure.net)."
  type        = string
  default     = null
}

variable "enable_function_app_private_endpoint" {
  description = "Whether to create a private endpoint for the Function App."
  type        = bool
  default     = false
}

variable "function_app_private_dns_zone_id" {
  description = "Private DNS zone ID for Function App private endpoint (privatelink.azurewebsites.net)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
