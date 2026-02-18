project_name = "azure-func-sample"
location     = "eastus2"

resource_group_name = "rg-azure-func-sample-prod"
app_service_plan_sku = "EP1"
python_version       = "3.11"
enable_stage_slot    = true
stage_slot_name      = "stage"

tags = {
  environment = "prod"
  workload    = "azure-function"
}
