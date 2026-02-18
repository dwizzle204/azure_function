project_name = "azure-func-sample"
location     = "eastus2"

resource_group_name = "rg-azure-func-sample-dev"
app_service_plan_sku = "Y1"
python_version       = "3.11"

tags = {
  environment = "dev"
  workload    = "azure-function"
}
