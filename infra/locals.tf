locals {
  workspace   = terraform.workspace
  name_prefix = lower(replace("${var.project_name}-${local.workspace}", "_", "-"))

  resource_group_name = var.resource_group_name
  service_plan_name   = "asp-${local.name_prefix}"
  function_app_name   = "func-${local.name_prefix}"

  common_tags = merge(
    var.tags,
    {
      project     = var.project_name
      environment = local.workspace
      managed_by  = "terraform"
    }
  )
}
