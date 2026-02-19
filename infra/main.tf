resource "random_string" "storage_suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "random_string" "key_vault_suffix" {
  length  = 5
  upper   = false
  lower   = true
  numeric = true
  special = false
}

data "azurerm_client_config" "current" {}
data "azurerm_resource_group" "this" {
  name = local.resource_group_name
}

locals {
  storage_account_base = substr(lower(replace(var.project_name, "-", "")), 0, 16)
  storage_account_name = "st${local.storage_account_base}${random_string.storage_suffix.result}"
  key_vault_base       = substr(lower(replace(local.name_prefix, "-", "")), 0, 17)
  key_vault_name       = "kv${local.key_vault_base}${random_string.key_vault_suffix.result}"

  vnet_integration_enabled         = var.enable_vnet_integration && var.function_app_integration_subnet_id != null
  storage_private_endpoint_enabled = var.enable_storage_private_endpoint && var.private_endpoint_subnet_id != null
  key_vault_private_endpoint_enabled = (
    var.enable_key_vault &&
    var.enable_key_vault_private_endpoint &&
    var.private_endpoint_subnet_id != null
  )
  function_app_private_endpoint_enabled = var.enable_function_app_private_endpoint && var.private_endpoint_subnet_id != null

  function_app_settings = merge(
    {
      FUNCTIONS_WORKER_RUNTIME                      = "python"
      WEBSITE_RUN_FROM_PACKAGE                      = "1"
      APPLICATIONINSIGHTS_CONNECTION_STRING         = azurerm_application_insights.this.connection_string
      WEBSITE_OVERRIDE_STICKY_DIAGNOSTICS_SETTINGS = "0"
      WEBSITE_OVERRIDE_STICKY_EXTENSION_VERSIONS   = "0"
    },
    local.vnet_integration_enabled ? {
      WEBSITE_VNET_ROUTE_ALL = "1"
    } : {},
    var.enable_key_vault ? {
      KEY_VAULT_URI = azurerm_key_vault.this[0].vault_uri
    } : {}
  )
}

resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  tags                     = local.common_tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_service_plan" "this" {
  name                = local.service_plan_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
  tags                = local.common_tags
}

resource "azurerm_application_insights" "this" {
  name                = "appi-${local.name_prefix}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  application_type    = "web"
  tags                = local.common_tags
}

resource "azurerm_key_vault" "this" {
  count                       = var.enable_key_vault ? 1 : 0
  name                        = local.key_vault_name
  location                    = data.azurerm_resource_group.this.location
  resource_group_name         = data.azurerm_resource_group.this.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.key_vault_sku_name
  purge_protection_enabled    = true
  soft_delete_retention_days  = var.key_vault_soft_delete_retention_days
  enable_rbac_authorization   = true
  public_network_access_enabled = true
  tags                        = local.common_tags
}

resource "azurerm_linux_function_app" "this" {
  name                       = local.function_app_name
  resource_group_name        = data.azurerm_resource_group.this.name
  location                   = data.azurerm_resource_group.this.location
  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  functions_extension_version = var.functions_extension_version
  https_only                  = true
  virtual_network_subnet_id   = local.vnet_integration_enabled ? var.function_app_integration_subnet_id : null

  identity {
    type = "SystemAssigned"
  }

  site_config {
    http2_enabled = true
    minimum_tls_version = "1.2"
    ftps_state = "Disabled"

    application_stack {
      python_version = var.python_version
    }
  }

  app_settings = local.function_app_settings

  tags = local.common_tags

  lifecycle {
    precondition {
      condition     = !var.enable_vnet_integration || var.function_app_integration_subnet_id != null
      error_message = "function_app_integration_subnet_id must be set when enable_vnet_integration is true."
    }
  }
}

resource "azurerm_linux_function_app_slot" "stage" {
  count           = var.enable_stage_slot ? 1 : 0
  name            = var.stage_slot_name
  function_app_id = azurerm_linux_function_app.this.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    http2_enabled = true
    minimum_tls_version = "1.2"
    ftps_state = "Disabled"

    application_stack {
      python_version = var.python_version
    }
  }

  app_settings = local.function_app_settings

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "storage_blob" {
  count               = local.storage_private_endpoint_enabled ? 1 : 0
  name                = "pe-stblob-${local.name_prefix}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-stblob-${local.name_prefix}"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.storage_private_dns_zone_id != null ? [var.storage_private_dns_zone_id] : []
    content {
      name                 = "pdzg-stblob-${local.name_prefix}"
      private_dns_zone_ids = [private_dns_zone_group.value]
    }
  }
}

resource "azurerm_private_endpoint" "key_vault" {
  count               = local.key_vault_private_endpoint_enabled ? 1 : 0
  name                = "pe-kv-${local.name_prefix}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-kv-${local.name_prefix}"
    private_connection_resource_id = azurerm_key_vault.this[0].id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.key_vault_private_dns_zone_id != null ? [var.key_vault_private_dns_zone_id] : []
    content {
      name                 = "pdzg-kv-${local.name_prefix}"
      private_dns_zone_ids = [private_dns_zone_group.value]
    }
  }
}

resource "azurerm_private_endpoint" "function_app" {
  count               = local.function_app_private_endpoint_enabled ? 1 : 0
  name                = "pe-func-${local.name_prefix}"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.common_tags

  private_service_connection {
    name                           = "psc-func-${local.name_prefix}"
    private_connection_resource_id = azurerm_linux_function_app.this.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.function_app_private_dns_zone_id != null ? [var.function_app_private_dns_zone_id] : []
    content {
      name                 = "pdzg-func-${local.name_prefix}"
      private_dns_zone_ids = [private_dns_zone_group.value]
    }
  }
}
