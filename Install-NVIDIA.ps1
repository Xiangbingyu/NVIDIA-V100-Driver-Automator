<#
.NOTES
必须使用管理员权限运行
需提前解压驱动文件到指定路径
#>

# 修改后的权限验证模块（替换原始代码）
param(
    [switch]$AutoInstall = $false
)

if (-not $AutoInstall) {
    # 手动运行时需要UAC提权
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -AutoInstall" -Verb RunAs
        exit
    }
}
else {
    # 计划任务运行时自动跳过提权
    $host.UI.RawUI.WindowTitle = "NVIDIA AutoInstall [Silent Mode]"
    $env:AutoInstall = "True"  # 设置环境变量供后续逻辑使用
}

# 配置参数
$driverPath = "D:\Driver\551.61-data-center-tesla-desktop-win10-win11-64bit-dch-international\Display.Driver"
$infFile = "nv_dispwi.inf"
$logPath = "$env:ProgramData\NVIDIA_AutoInstall.log"

# 初始化日志
Start-Transcript -Path $logPath -Append
Write-Output "===== 脚本开始执行 $(Get-Date) ====="

try {
    # 阶段1：精确驱动安装
    Write-Output "`n[阶段1] 驱动安装流程..."
    
    # 验证驱动文件
    $infFullPath = Join-Path -Path $driverPath -ChildPath $infFile
    if (-not (Test-Path $infFullPath)) {
        throw "驱动文件不存在：$infFullPath"
    }

    # 获取目标设备
    $targetDevice = Get-PnpDevice -FriendlyName "*3D 视频控制器*" -ErrorAction Stop
    if (-not $targetDevice) {
        throw "未找到3D视频控制器设备"
    }
    $instanceID = $targetDevice.InstanceId

    # 通过设备管理器安装驱动
    Write-Output "正在安装NVIDIA Tesla v100 sxm2 16G驱动..."
    pnputil /add-driver $infFullPath /install /instanceid $instanceID
    
    if ($LASTEXITCODE -ne 0) {
        throw "驱动安装失败，错误代码：$LASTEXITCODE"
    }

    # 阶段2：注册表修改
    Write-Output "`n[阶段2] 注册表配置..."
    
    # 注册表路径配置
    $regPath0001 = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001"
    $regPath0000 = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"

    # 定义操作清单
    $regOperations = @(
        @{Path=$regPath0001; Name="AdapterType"; Action="Set"; Value=1; Type="DWord"},
        @{Path=$regPath0001; Name="FeatureScore"; Action="Set"; Value=0xD1; Type="DWord"},
        @{Path=$regPath0001; Name="GridLicensedFeatures"; Action="Create"; Value=7; Type="DWord"},
        @{Path=$regPath0001; Name="AdapterType"; Action="Delete"},
        @{Path=$regPath0001; Name="EnableMsHybrid"; Action="Create"; Value=1; Type="DWord"},
        @{Path=$regPath0000; Name="Refresh"; Action="Read"}
    )

    # 执行注册表操作
    foreach ($op in $regOperations) {
        try {
            if (-not (Test-Path $op.Path)) {
                throw "注册表路径不存在：$($op.Path)"
            }

            switch ($op.Action) {
                "Set" {
                    Set-ItemProperty -Path $op.Path -Name $op.Name -Value $op.Value -Type $op.Type -Force
                    Write-Output "已设置 $($op.Path)\$($op.Name) = $($op.Value)"
                }
                "Create" {
                    New-ItemProperty -Path $op.Path -Name $op.Name -Value $op.Value -Type $op.Type -Force | Out-Null
                    Write-Output "已创建 $($op.Path)\$($op.Name)"
                }
                "Delete" {
                    Remove-ItemProperty -Path $op.Path -Name $op.Name -Force -ErrorAction Stop
                    Write-Output "已删除 $($op.Path)\$($op.Name)"
                }
                "Read" {
                    Get-ItemProperty -Path $op.Path | Out-Null
                    Write-Output "已刷新 $($op.Path)"
                }
            }
        }
        catch {
            Write-Warning "操作失败：$($op.Action) $($op.Name) - $_"
        }
    }

    # 阶段3：重启确认
    Write-Output "`n[阶段3] 系统重启准备"
    Write-Output "系统即将自动重启..."
    shutdown /r /t 5 /f
    Write-Output "重启命令已执行，系统将在5秒后自动重启"
}
catch {
    Write-Error "严重错误：$_"
    Read-Host "按Enter退出..."
    exit 1
}
finally {
    Stop-Transcript
}