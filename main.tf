# Install the CW Agent
resource "aws_ssm_document" "CloudWatchAgentInstallAndConfigure" {
  name          = "CloudWatchAgentInstallAndConfigure"
  document_type = "Command"
  content       = <<DOC
{
  "schemaVersion": "2.2",
  "description": "A composite document for installing and configuring CloudWatchAgent.",
  "mainSteps": [
    {
      "action": "aws:runDocument",
      "name": "installCWAgent",
      "inputs": {
        "documentType": "SSMDocument",
        "documentPath": "AWS-ConfigureAWSPackage",
        "documentParameters": "{\"action\":\"Install\",\"name\" : \"AmazonCloudWatchAgent\"}"
      }
    },
    {
      "action": "aws:runDocument",
      "name": "second",
      "inputs": {
        "documentType": "SSMDocument",
        "documentPath": "AmazonCloudWatch-ManageAgent",
        "documentParameters": "{\"action\":\"configure\",\"mode\" : \"ec2\",           \"optionalConfigurationSource\" : \"default\",\"optionalRestart\" : \"yes\"}"
      }
    }
  ]
}
DOC
}


# Update CloudWatch Agent weekly on all EC2 Instances
resource "aws_ssm_association" "cloudwatch_agent_biweekly_all" {
  name                = aws_ssm_document.update_cloudwatch_agent_biweekly_all.id
  association_name    = "SystemAssociationForUpdateCloudWatchAgent"
  schedule_expression = var.cloudwatch_agent_update_schedule

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}


# Update CloudWatch Agent weekly on all EC2 Instances
resource "aws_ssm_document" "update_cloudwatch_agent_biweekly_all" {
  name          = "CloudWatchAgentUpdatebiweekly"
  document_type = "Command"
  content       = <<DOC
{
  "schemaVersion": "2.2",
  "description": "A composite document for updating CloudWatchAgent.",
  "mainSteps": [
    {
      "precondition": {
        "StringEquals": [
          "platformType",
          "Linux"
        ]
      },
      "action": "aws:runShellScript",
      "name": "first",
      "inputs": {
        "runCommand": [
          "sleep 1800"
        ]
      }
    },
    {
      "precondition": {
        "StringEquals": [
          "platformType",
          "Windows"
        ]
      },
      "action": "aws:runPowerShellScript",
      "name": "second",
      "inputs": {
        "runCommand": [
          "Start-Sleep –Seconds 1800"
        ]
      }
    },
    {
      "action": "aws:runDocument",
      "name": "installCWAgent",
      "inputs": {
        "documentType": "SSMDocument",
        "documentPath": "AWS-ConfigureAWSPackage",
        "documentParameters": "{\"action\":\"Install\",\"name\" : \"AmazonCloudWatchAgent\"}"
      }
    }
  ]
}
DOC
}


# Generate the main template file, like amazon-cloudwatch-agent_windows_base.json.tmpl
# Generate the log files collect_list, like amazon-cloudwatch-agent_windows_iis.logs.tmpl
# Generate the WindowsPerfMon metrics_collected list, like amazon-cloudwatch-agent_windows_iis.perfmon_metrics.tmpl
#
# We could just append multiple JSON files per
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-common-scenarios.html#CloudWatch-Agent-multiple-config-files
resource "local_file" "cw_agent_configs_windows" {
  for_each = var.windows_cw_agent_templates
  filename = "${path.module}/amazon-cloudwatch-agent_${each.key}.json"
  content  = templatefile("${path.module}/templates/${each.value.windows_base}",
    {
      windows_logs = length(each.value.windows_logs) == 0 ? "" : "${join(",\n",
        [ for log_template in each.value.windows_logs :
          chomp(
            templatefile(
              "${path.module}/templates/${log_template}",
              {}
            )
          )
        ]
      )},\n"
      perfmon_metrics = length(each.value.perfmon_metrics) == 0 ? "" : "${join(",\n",
        [ for perfmon_metric in each.value.perfmon_metrics :
          chomp(
            templatefile(
              "${path.module}/templates/${perfmon_metric}",
              {}
            )
          )
        ]
      )},\n"
    }
  )
}


resource "local_file" "cw_agent_configs_linux" {
  for_each = var.linux_cw_agent_templates
  filename = "${path.module}/amazon-cloudwatch-agent_${each.key}.json"
  content  = templatefile("${path.module}/templates/${each.value.linux_base}",
    {
      linux_logs = length(each.value.linux_logs) == 0 ? "" : "${join(",\n",
        [ for log_template in each.value.linux_logs :
          chomp(
            templatefile(
              "${path.module}/templates/${log_template}",
              {}
            )
          )
        ]
      )},\n"
      linux_metrics = length(each.value.linux_metrics) == 0 ? "" : "${join(",\n",
        [ for linux_metric in each.value.linux_metrics :
          chomp(
            templatefile(
              "${path.module}/templates/${linux_metric}",
              {}
            )
          )
        ]
      )},\n"
    }
  )
}


# Store the Windows config.json files in SSM Parameter Store
resource "aws_ssm_parameter" "cw_agent_config_windows" {
  for_each = var.windows_cw_agent_templates
  name     = "cw_agent_config_windows_${each.key}"
  type     = "String"
  tier     = "Advanced"
  value    = templatefile("${path.module}/templates/${each.value.windows_base}",
    {
      windows_logs = length(each.value.windows_logs) == 0 ? "" : "${join(",\n",
        [ for log_template in each.value.windows_logs :
          chomp(
            templatefile(
              "${path.module}/templates/${log_template}",
              {}
            )
          )
        ]
      )},\n"
      perfmon_metrics = length(each.value.perfmon_metrics) == 0 ? "" : "${join(",\n",
        [ for perfmon_metric in each.value.perfmon_metrics :
          chomp(
            templatefile(
              "${path.module}/templates/${perfmon_metric}",
              {}
            )
          )
        ]
      )},\n"
    }
  )
}


# Store the Linux config.json files in SSM Parameter Store
resource "aws_ssm_parameter" "cw_agent_config_linux" {
  for_each = var.linux_cw_agent_templates
  name     = "cw_agent_config_linux_${each.key}"
  type     = "String"
  tier     = "Advanced"
  value    = templatefile("${path.module}/templates/${each.value.linux_base}",
    {
      linux_logs = length(each.value.linux_logs) == 0 ? "" : "${join(",\n",
        [ for log_template in each.value.linux_logs :
          chomp(
            templatefile(
              "${path.module}/templates/${log_template}",
              {}
            )
          )
        ]
      )},\n"
      linux_metrics = length(each.value.linux_metrics) == 0 ? "" : "${join(",\n",
        [ for linux_metric in each.value.linux_metrics :
          chomp(
            templatefile(
              "${path.module}/templates/${linux_metric}",
              {}
            )
          )
        ]
      )},\n"
    }
  )
}


# Push the Windows config.json file from SSM Parameter Store to the Windows EC2 Instances
resource "aws_ssm_association" "push_cw_agent_config_windows" {
  for_each         = var.windows_cw_agent_templates
  name             = "AmazonCloudWatch-ManageAgent"
  association_name = "AssociateWindowsInstancesWithBaseCWConfigWindows${each.key}"

  targets {
    key    = "tag:CwAgentConfigKey"
    values = [each.key]
  }

  parameters = {
    mode                          = "ec2"
    action                        = "configure"
    optionalRestart               = "yes"
    optionalConfigurationSource   = "ssm"
    optionalConfigurationLocation = "cw_agent_config_windows_${each.key}"
  }
}

# Push the Linux config.json file from SSM Parameter Store to the Linux EC2 Instances
resource "aws_ssm_association" "push_cw_agent_config_linux" {
  for_each            = var.linux_cw_agent_templates
  name                = "AmazonCloudWatch-ManageAgent"
  association_name    = "AssociateLinuxInstancesWithBaseCWConfigLinux${each.key}"
  schedule_expression = var.cloudwatch_agent_configure_schedule
  targets {
    key    = "tag:CwAgentConfigKey"
    values = [each.key]
  }
  parameters = {
    mode                          = "ec2"
    action                        = "configure"
    optionalRestart               = "yes"
    optionalConfigurationSource   = "ssm"
    optionalConfigurationLocation = "cw_agent_config_linux_${each.key}"
  }
}


# Modify the CloudWatch Agent config based on the Logical Disks (C:, D:, X:, etc.) seen by Windows.
# This modifies the CW Agent config on the Windows machine, so it will change the config pushed via SSM!
resource "aws_ssm_document" "modify_cw_agent_config" {
  name          = "ModifyCloudWatchAgentConfig"
  document_type = "Command"
  content       = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Modify the CloudWatch Agent config based on the Logical Disks (C:, D:, X:, etc.) seen by Windows",
  "mainSteps": [
    {
      "action": "aws:runPowerShellScript",
      "name": "ModifyCloudWatchAgentConfig",
      "precondition": {
        "StringEquals": ["platformType", "Windows"]
      },
      "inputs": {
        "runCommand": [
          ${jsonencode(file("${path.module}/update_cw_config.ps1"))}
        ],
        "executionTimeout": "300",
        "workingDirectory": ""
      }
    }
  ]
}
DOC
}


# Modify the CloudWatch Agent config based on the Logical Disks (C:, D:, X:, etc.) seen by Windows.
# This modifies the CW Agent config on the Windows machine, so it will change the config pushed via SSM!
resource "aws_ssm_association" "modify_cw_agent_config_on_demand" {
  name             = aws_ssm_document.modify_cw_agent_config.id
  association_name = "ModifyCloudWatchAgentConfigOnWindows"

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}


# Associate AWS-RunPatchBaseline SSM Document with all EC2 Instances: Scan
resource "aws_ssm_association" "aws_run_patch_baseline_scan" {
  name                = "AWS-RunPatchBaseline"
  association_name    = "SystemAssociationForScanningPatches"
  schedule_expression = var.ssm_patch_scan_schedule

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }

  parameters = {
    Operation    = "Scan"
    RebootOption = "NoReboot"
  }
}


# Get Inventory every hour for all EC2 Instances
resource "aws_ssm_association" "aws_gather_software_inventory" {
  name                = "AWS-GatherSoftwareInventory"
  association_name    = "AssociateAllInstanceIdsWithAWSGatherSoftwareInventory"
  schedule_expression = var.ssm_inventory_scan_schedule

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }

  parameters = {
    applications                = "Enabled"
    awsComponents               = "Enabled"
    customInventory             = "Enabled"
    instanceDetailedInformation = "Enabled"
    networkConfig               = "Enabled"
    services                    = "Enabled"
    windowsRoles                = "Enabled"
    windowsUpdates              = "Enabled"
  }
}


# Keep SSM Agent up to date on all EC2 Instances
resource "aws_ssm_association" "aws_update_ssm_agent" {
  name                = "AWS-UpdateSSMAgent"
  association_name    = "SystemAssociationForSsmAgentUpdate"
  schedule_expression = var.ssm_agent_update_schedule

  targets {
    key    = "InstanceIds"
    values = ["*"]
  }
}
