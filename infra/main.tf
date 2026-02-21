data "azurerm_client_config" "current" {}
data "azurerm_resource_group" "this" {
  name = local.resource_group_name
}

locals {
  storage_account_prefix = substr(lower(replace(local.name_prefix, "-", "")), 0, 16)
  storage_account_hash   = substr(sha1("${local.name_prefix}-${data.azurerm_client_config.current.subscription_id}"), 0, 6)
  storage_account_name   = "st${local.storage_account_prefix}${local.storage_account_hash}"
  key_vault_base       = substr(lower(replace(local.name_prefix, "-", "")), 0, 17)
  key_vault_name       = "kv${local.key_vault_base}"

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
      FUNCTIONS_WORKER_RUNTIME                     = "python"
      WEBSITE_RUN_FROM_PACKAGE                     = "1"
      WEBSITE_OVERRIDE_STICKY_DIAGNOSTICS_SETTINGS = "0"
      WEBSITE_OVERRIDE_STICKY_EXTENSION_VERSIONS   = "0"
    },
    var.application_insights_connection_string != null ? {
      APPLICATIONINSIGHTS_CONNECTION_STRING = var.application_insights_connection_string
    } : {},
    local.vnet_integration_enabled ? {
      WEBSITE_VNET_ROUTE_ALL = "1"
    } : {},
    var.enable_key_vault ? {
      KEY_VAULT_URI = "https://${module.key_vault[0].name}.vault.azure.net/"
    } : {}
  )
  storage_endpoints = local.storage_private_endpoint_enabled ? {
    blob = {
      type                         = "blob"
      private_dns_zone_resource_id = var.storage_private_dns_zone_id
    }
  } : {}

  function_private_endpoints = local.function_app_private_endpoint_enabled ? {
    primary = merge(
      {
        subnet_resource_id = var.private_endpoint_subnet_id
      },
      var.function_app_private_dns_zone_id != null ? {
        private_dns_zone_resource_ids = [var.function_app_private_dns_zone_id]
      } : {}
    )
  } : {}

  key_vault_private_endpoints = local.key_vault_private_endpoint_enabled ? {
    primary = merge(
      {
        subnet_resource_id = var.private_endpoint_subnet_id
      },
      var.key_vault_private_dns_zone_id != null ? {
        private_dns_zone_resource_ids = [var.key_vault_private_dns_zone_id]
      } : {}
    )
  } : {}
}

module "key_vault" {
  count = var.enable_key_vault ? 1 : 0

  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                = local.key_vault_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  public_network_access_enabled = false
  private_endpoints             = local.key_vault_private_endpoints
  tags                          = local.common_tags

  enable_telemetry = false
}

module "function_app_pattern" {
  source  = "Azure/avm-ptn-function-app-storage-private-endpoints/azurerm"
  version = "0.2.1"

  name                = local.function_app_name
  location            = data.azurerm_resource_group.this.location
  os_type             = "Linux"
  resource_group_name = data.azurerm_resource_group.this.name

  create_service_plan = true
  service_plan = {
    name                = local.service_plan_name
    resource_group_name = data.azurerm_resource_group.this.name
    location            = data.azurerm_resource_group.this.location
    sku_name            = var.app_service_plan_sku
  }

  create_secure_storage_account = true
  storage_account = {
    name                     = local.storage_account_name
    resource_group_name      = data.azurerm_resource_group.this.name
    account_replication_type = "LRS"
    endpoints                = local.storage_endpoints
  }

  app_settings                        = local.function_app_settings
  functions_extension_version         = var.functions_extension_version
  https_only                          = true
  public_network_access_enabled       = !local.function_app_private_endpoint_enabled
  virtual_network_subnet_id           = local.vnet_integration_enabled ? var.function_app_integration_subnet_id : null
  private_endpoint_subnet_resource_id = var.private_endpoint_subnet_id
  private_endpoints                   = local.function_private_endpoints

  site_config = {
    ftps_state          = "Disabled"
    minimum_tls_version = "1.2"
    http2_enabled       = true
    application_stack = {
      python = {
        python_version = var.python_version
      }
    }
  }

  deployment_slots = var.enable_stage_slot ? {
    stage = {
      name         = var.stage_slot_name
      app_settings = local.function_app_settings
      site_config = {
        ftps_state          = "Disabled"
        minimum_tls_version = "1.2"
        http2_enabled       = true
        application_stack = {
          python = {
            python_version = var.python_version
          }
        }
      }
    }
  } : {}

  tags = local.common_tags

  enable_telemetry = false

  depends_on = [module.key_vault]
}
