variable "customer" {
  type    = string
  default = "BigCompany LLC"
}

variable "application" {
  type    = string
  default = "BigCompany Web Site"
}

variable "environment" {
  type        = string
  description = "The name of the environment, such as 'dev', 'test', or 'prod'"
  default     = "dev"
}

variable "cloudwatch_agent_update_schedule" {
  type        = string
  description = "cron/rate expression for Cloudwatch Agent Update"
  default     = "rate(7 days)"
}

variable "ssm_agent_update_schedule" {
  type        = string
  description = "cron/rate expression for SSM Agent Update"
  default     = "rate(14 days)"
}

variable "ssm_inventory_scan_schedule" {
  type        = string
  description = "cron/rate expression for gathering Software Inventory"
  default     = "rate(1 hour)"
}

variable "ssm_patch_scan_schedule" {
  type        = string
  description = "cron/rate expression for OS Patch Scan"
  default     = "rate(1 hour)"
}

variable "ssm_patch_install_schedule" {
  type        = string
  description = "cron/rate expression for OS Patch Install. Default is 0200 every Monday morning."
  default     = "cron(0 2 ? * MON *)"
}

variable "patch_baseline_reboot_option" {
  type        = string
  description = "https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-about-aws-runpatchbaseline.html#patch-manager-about-aws-runpatchbaseline-parameters-norebootoption"
  default     = "NoReboot"
}

variable "windows_cw_agent_templates" {
  type = map(object({
    windows_base    = string
    windows_logs    = list(string)
    perfmon_metrics = list(string)
  }))
  description = "Base template (string) + any other partial configuration templates (list(string)) to merge into the base template. All must be under ./templates/"
  default = {
    iis_mssql = {
      windows_base = "amazon-cloudwatch-agent_windows_base.json.tmpl"
      windows_logs = [
        "amazon-cloudwatch-agent_windows_iis.logs.tmpl",
        "amazon-cloudwatch-agent_windows_mssql.logs.tmpl"
      ]
      perfmon_metrics = [
        "amazon-cloudwatch-agent_windows_iis.perfmon_metrics.tmpl",
        "amazon-cloudwatch-agent_windows_mssql.perfmon_metrics.tmpl"
      ]
    }
  }
}

variable "linux_cw_agent_templates" {
  type = map(object({
    linux_base    = string
    linux_logs    = list(string)
    linux_metrics = list(string)
  }))
  description = "Base template (string) + any other partial configuration templates (list(string)) to merge into the base template. All must be under ./templates/"
  default = {}
}
