resource "random_string" "storage_suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  storage_account_base = substr(lower(replace(var.project_name, "-", "")), 0, 16)
  storage_account_name = "st${local.storage_account_base}${random_string.storage_suffix.result}"
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.common_tags
}

resource "azurerm_service_plan" "this" {
  name                = local.service_plan_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
  tags                = local.common_tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${local.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  application_type    = "web"
  tags                = local.common_tags
}

resource "azurerm_linux_function_app" "this" {
  name                       = local.function_app_name
  resource_group_name        = azurerm_resource_group.this.name
  location                   = azurerm_resource_group.this.location
  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  functions_extension_version = var.functions_extension_version
  https_only                 = true

  site_config {
    application_stack {
      python_version = var.python_version
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME              = "python"
    WEBSITE_RUN_FROM_PACKAGE              = "1"
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this.connection_string
  }

  tags = local.common_tags
}

resource "azurerm_linux_function_app_slot" "stage" {
  name            = "stage"
  function_app_id = azurerm_linux_function_app.this.id

  site_config {
    application_stack {
      python_version = var.python_version
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME              = "python"
    WEBSITE_RUN_FROM_PACKAGE              = "1"
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this.connection_string
  }

  tags = local.common_tags
}
