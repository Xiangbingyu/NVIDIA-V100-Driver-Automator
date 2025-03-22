# NVIDIA-V100-Driver-Automator
NVIDIA Tesla V100 显卡驱动自动化管理套件

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://learn.microsoft.com/zh-cn/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

⚠️ **解决痛点**：  
- 数据中心显卡驱动安装后重启失效  
- 设备管理器频繁出现"3D 视频控制器"未识别  
- 需反复手动修改注册表  

✨ **核心功能**：  
- 一键式驱动安装与注册表修复  
- 开机自检驱动完整性（双验证机制）  
- 支持Windows 10/11系统环境  

🚀 **快速开始**：  
```powershell
irm https://raw.githubusercontent.com/yourname/repo/main/Setup-AutoCheck.ps1 | iex

📚 **使用场景**：
- 本地深度学习工作站搭建
- 多显卡计算节点维护
- Tesla系列显卡游戏魔改

🔧 **技术亮点**：
- 注册表动态检测（自动适配0000/0001设备号）
- 静默安装模式（无GUI干扰）
- 驱动文件哈希校验
