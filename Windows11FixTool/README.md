# Windows 11 Fix Tool

> 一个功能强大的 Windows 11 系统优化工具，通过简单的批处理脚本实现系统定制功能。

![Windows 11](https://img.shields.io/badge/Windows-11-0078D4?style=flat-square&logo=windows&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
![Language](https://img.shields.io/badge/language-Batch-blue?style=flat-square)

## ✨ 功能特性

本工具提供以下系统优化功能：

- **🖱️ 右键菜单定制**
  - 显示完整右键菜单（恢复 Windows 10 风格）
  - 显示紧凑右键菜单（Windows 11 默认风格）

- **📁 文件资源管理器界面切换**
  - 启用新版文件资源管理器界面
  - 启用经典版文件资源管理器界面

- **⌨️ F1 键功能管理**
  - 禁用 F1 键打开 Edge 帮助（避免误触）
  - 启用 F1 键打开 Edge 帮助

- **⏸️ Windows 更新暂停管理**
  - 延长 Windows 11 更新暂停时长（最长可达 7300 天）

- **🛡️ Windows Defender 管理**
  - 禁用 Windows Defender（通过注册表关闭实时保护）
  - 启用 Windows Defender（恢复默认保护状态）

## 📋 系统要求

- **操作系统：** Windows 11 (22H2 及以上版本)
- **权限要求：** 管理员权限
- **其他：** 无需额外依赖

## 🚀 使用方法

### 方式一：直接运行（推荐）

1. **右键点击** `Windows11FixTool.bat`
2. 选择 **"以管理员身份运行"**
3. 在菜单中输入对应的数字选项
4. 按照提示操作

### 方式二：命令行运行

```cmd
# 以管理员身份打开命令提示符，然后运行：
Windows11FixTool.bat
```

## 📖 功能详解

### 1. 显示完整右键菜单

**功能说明：** 恢复 Windows 10 风格的完整右键菜单，显示所有选项。

**适用场景：** 习惯传统右键菜单的用户，希望快速访问所有功能。

**生效方式：** 需要重启计算机

### 2. 显示紧凑右键菜单

**功能说明：** 切换回 Windows 11 默认的紧凑右键菜单。

**适用场景：** 喜欢 Windows 11 新界面风格的用户。

**生效方式：** 需要重启计算机

### 3. 启用新版文件资源管理器界面

**功能说明：** 使用 Windows 11 原生的现代化文件资源管理器界面。

**适用场景：** 享受最新的 Windows 11 设计体验。

**生效方式：** 需要重启文件资源管理器

### 4. 启用经典版文件资源管理器界面

**功能说明：** 恢复经典的文件资源管理器布局和功能。

**适用场景：** 偏好传统界面布局，或新版界面出现兼容性问题时。

**生效方式：** 需要重启文件资源管理器

### 5. 禁用 F1 键 Edge 帮助

**功能说明：** 禁用 F1 键自动打开 Microsoft Edge 浏览器的帮助页面。

**适用场景：** 避免游戏中或工作时误触 F1 键导致浏览器弹出。

**生效方式：** 立即生效

### 6. 启用 F1 键 Edge 帮助

**功能说明：** 恢复 F1 键的默认帮助功能。

**适用场景：** 需要使用 F1 键快速访问帮助文档时。

**生效方式：** 立即生效

### 7. 延长 Windows 更新暂停时长

**功能说明：** 将 Windows 更新暂停的最大时长从默认值延长到 7300 天（约 20 年）。

**适用场景：**
- 希望长期控制系统更新时机
- 专业工作站环境需要避免自动更新中断工作
- 测试环境需要保持系统版本稳定

**生效方式：** 立即生效，需要在 设置 → Windows 更新 中手动暂停更新

### 8. 禁用 Windows Defender

**功能说明：** 通过修改注册表禁用 Windows Defender 的反间谍软件和实时保护功能。

**适用场景：**
- 安装第三方杀毒软件前需要关闭 Windows Defender
- 特定软件与 Windows Defender 存在兼容性问题
- 测试或开发环境需要临时关闭防护

**生效方式：** 需要重启计算机

**⚠️ 警告：** 禁用 Windows Defender 会降低系统安全性，请确保已安装替代的安全软件！

### 9. 启用 Windows Defender

**功能说明：** 恢复 Windows Defender 的默认保护状态，重新启用反间谍软件和实时保护。

**适用场景：**
- 需要恢复系统默认安全防护
- 不再需要第三方杀毒软件时重新启用自带保护

**生效方式：** 需要重启计算机

## 🔧 技术原理

本工具通过修改 Windows 注册表实现各项功能：

- **右键菜单：** 修改 `HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` 注册表项
- **文件资源管理器：** 修改 `HKCU\Software\Classes\CLSID\` 下的相关 CLSID 项
- **F1 键：** 修改 `HKCU\SOFTWARE\Classes\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}` 注册表项
- **更新暂停：** 修改 `HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings\FlightSettingsMaxPauseDays` 注册表项
- **Windows Defender：** 修改 `HKLM\SOFTWARE\Policies\Microsoft\Windows Defender` 下的 `DisableAntiSpyware` 和 `DisableRealtimeMonitoring` 注册表值

## ⚠️ 注意事项

1. **管理员权限：** 必须以管理员身份运行，否则修改注册表会失败
2. **系统重启：** 右键菜单和文件资源管理器的修改需要重启相关组件才能生效
3. **备份建议：** 修改注册表前建议创建系统还原点
4. **兼容性：** 仅适用于 Windows 11 22H2 及以上版本
5. **更新暂停：** 长期不更新系统可能存在安全风险，请根据实际情况谨慎使用

## 🔒 安全性说明

- 本工具仅修改注册表中与指定功能相关的项
- 不涉及任何系统核心设置或敏感数据
- 所有修改都是可逆的（可通过脚本切换回默认设置）
- 不收集任何用户数据或上传信息

## 📝 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📮 联系方式

如有问题或建议，欢迎通过以下方式联系：

- 提交 GitHub Issue
- 发送邮件反馈

---

**💡 提示：** 使用前建议创建系统还原点，以便在出现问题时快速恢复！

**⚡ 快速开始：** 右键以管理员身份运行 `Windows11FixTool.bat`，选择需要的功能即可！
