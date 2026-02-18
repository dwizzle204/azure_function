variable "project_name" {
  description = "Short project identifier used in resource naming."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "resource_group_name" {
  description = "Optional override for the resource group name."
  type        = string
  default     = null
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

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
