project_name = "azure-func-sample"

resource_group_name = "rg-azure-func-sample-dev"
app_service_plan_sku = "Y1"
python_version       = "3.11"
enable_stage_slot    = false

enable_vnet_integration          = false
function_app_integration_subnet_id = null
private_endpoint_subnet_id       = null

enable_storage_private_endpoint      = false
storage_private_dns_zone_id          = null
enable_function_app_private_endpoint = false
function_app_private_dns_zone_id     = null
enable_key_vault                     = false
enable_key_vault_private_endpoint    = true
key_vault_private_dns_zone_id        = null

tags = {
  environment = "dev"
  workload    = "azure-function"
}
