# Setup-AutoCheck.ps1（部署脚本 - 管理员运行一次）
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 配置参数
$desktopPath = [Environment]::GetFolderPath("Desktop")
$checkScript = Join-Path $desktopPath "Check-Driver.ps1"

# 创建系统级计划任务
$taskParams = @{
    TaskName    = "NVIDIA Driver AutoCheck"
    Action      = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$checkScript`" -AutoInstall"
    Trigger     = New-ScheduledTaskTrigger -AtStartup
    Settings    = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries
    Principal   = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
}

Register-ScheduledTask @taskParams -Force | Out-Null

Write-Host "配置完成！系统将在每次启动时自动检测驱动状态。" -ForegroundColor Green
Write-Host "检测脚本位置：$checkScript" -ForegroundColor Cyan
Read-Host "按 Enter 退出..."