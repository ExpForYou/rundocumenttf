if (Test-Path "$Env:ProgramData\Amazon\AmazonCloudWatchAgent\Configs\ssm_cw_agent_config_windows_iis" -PathType leaf)
{
  mv $Env:ProgramData\Amazon\AmazonCloudWatchAgent\Configs\ssm_cw_agent_config_windows_iis $Env:ProgramData\Amazon\AmazonCloudWatchAgent\Configs\config.json
}

((Get-Content -path $Env:ProgramFiles\Amazon\AmazonCloudWatchAgent\config.json) -replace '(("[A-Z]{1}: "),?)+',"`"$((Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DriveType -eq "3" -and $_.Label -ne "System Reserved"} | select -expand DeviceID) -join '","')`"") | Set-Content -path $Env:ProgramFiles\Amazon\AmazonCloudWatchAgent\config.json

& $Env:ProgramFiles\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1 -m ec2 -a stop

& $Env:ProgramFiles\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1 -a fetch-config -m ec2 -c file:"C:\Program Files\Amazon\AmazonCloudWatchAgent\config.json" -s
