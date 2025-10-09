# Check-Driver.ps1（驱动检测脚本）
param([switch]$AutoInstall)

# 精准检测逻辑
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001"

# 双重验证机制
if (-not (Test-Path $regPath) -and 
    (Get-PnpDevice -FriendlyName "*3D 视频控制器*" -ErrorAction SilentlyContinue)) {
    
    # 静默提权执行安装脚本
    $installScript = Join-Path $PSScriptRoot "Install-NVIDIA.ps1"
    $args = @("-ExecutionPolicy Bypass", "-File `"$installScript`"")
    if ($AutoInstall) { $args += "-AutoInstall" }
    
    Start-Process powershell -ArgumentList $args -Verb RunAs -WindowStyle Hidden
}
