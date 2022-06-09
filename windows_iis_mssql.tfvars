windows_cw_agent_templates = {
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
