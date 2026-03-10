# 视频音频合并与重编码脚本

跨平台视频处理脚本，支持 Windows、Linux 和 macOS。

## 🚀 快速开始

只需两步，立即开始处理视频：

### Linux / macOS

```bash
# 1️⃣ 下载脚本到您的视频文件夹
cd /path/to/your/videos
curl -LJO https://raw.githubusercontent.com/RolinShmily/SrP-Scripts/main/video-merge-audio-reencode/video-merge-audio-reencode.sh
chmod +x video-merge-audio-reencode.sh

# 2️⃣ 直接运行（自动处理当前目录及所有子文件夹）
./video-merge-audio-reencode.sh
```

### Windows (WSL - 推荐) ⭐

使用 WSL 运行 bash 脚本，完美支持中文路径和空格！

```bash
# 1️⃣ 安装 WSL（如果还没安装）
wsl --install

# 2️⃣ 在 WSL 中安装 ffmpeg
sudo apt update && sudo apt install ffmpeg

# 3️⃣ 下载并运行脚本
cd "/mnt/e/你的视频文件夹"
curl -LJO https://raw.githubusercontent.com/RolinShmily/SrP-Scripts/main/video-merge-audio-reencode/video-merge-audio-reencode.sh
chmod +x video-merge-audio-reencode.sh
./video-merge-audio-reencode.sh
```

### Windows (PowerShell)

```powershell
# 1️⃣ 下载脚本到您的视频文件夹
cd "E:\你的视频文件夹"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/RolinShmily/SrP-Scripts/main/video-merge-audio-reencode/video-merge-audio-reencode.ps1" -OutFile "video-merge-audio-reencode.ps1"

# 2️⃣ 设置执行策略（首次使用）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 3️⃣ 运行脚本
.\video-merge-audio-reencode.ps1
```

就这么简单！处理后的视频会自动保存在 `output` 文件夹中。✨

---

## 功能特性

- 🔍 **自动扫描**：扫描指定目录中的 mkv/mov/mp4 视频文件（递归所有子文件夹）
- 🎵 **智能混音**：将每个视频的所有音频轨道混音合并为一个音轨
- 🚀 **硬件加速**：自动检测并使用最优编码器（Linux/macOS）
  - NVIDIA NVENC (独显) - 最快 ⚡
  - AMD AMF (独显)
  - Intel Quick Sync (核显)
  - VAAPI (Linux 核显)
  - VideoToolbox (macOS)
  - libx264 CPU (备选)
- 🎬 **H.264 编码**：使用 h.264 重新编码视频，智能参考源视频质量
- 📐 **保持参数**：自动保持原视频的分辨率和帧率
- 📦 **统一输出**：输出为标准 MP4 格式（带 FastStart，优化流媒体播放）
- 🎨 **彩色输出**：友好的彩色日志显示处理进度
- ⚡ **极速处理**：硬件编码速度提升 **10-50 倍**

## 系统要求

### Windows
- **推荐：** Windows 10/11 + WSL (Windows Subsystem for Linux)
- **备选：** PowerShell 5.1+
- FFmpeg (WSL: `sudo apt install ffmpeg` / Windows: 添加到 PATH)

### Linux
- 任何主流 Linux 发行版
- FFmpeg (通过包管理器安装)

### macOS
- macOS 10.12 或更高版本
- [Homebrew](https://brew.sh/) + FFmpeg

## 安装 FFmpeg

### Windows

#### 方案一：WSL (推荐)
```powershell
# 安装 WSL
wsl --install

# 在 WSL 中安装 ffmpeg
sudo apt update && sudo apt install ffmpeg
```

#### 方案二：PowerShell
1. 下载 FFmpeg：[https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)
2. 解压到目录（如 `C:\ffmpeg`）
3. 将 `C:\ffmpeg\bin` 添加到系统 PATH 环境变量
4. 重启 PowerShell，验证：`ffmpeg -version`

### Linux
```bash
# Arch Linux
sudo pacman -S ffmpeg

# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg

# Fedora
sudo dnf install ffmpeg

# openSUSE
sudo zypper install ffmpeg
```

### macOS
```bash
# 安装 Homebrew (如果还没安装)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 FFmpeg
brew install ffmpeg
```

## 使用方法

### 方式一：默认模式（推荐）⭐

将脚本放入包含视频文件的文件夹中，直接运行：

#### Linux / macOS
```bash
./video-merge-audio-reencode.sh
```

#### Windows (WSL)
```bash
# 在 WSL 终端中运行
cd "/mnt/e/你的视频文件夹"
./video-merge-audio-reencode.sh
```

#### Windows (PowerShell)
```powershell
.\video-merge-audio-reencode.ps1
```

**特点：**
- ✅ 自动处理当前目录及所有子文件夹中的视频文件
- ✅ 输出到当前目录下的 `output` 文件夹
- ✅ 所有输出的 MP4 文件统一保存到 output 目录

### 方式二：自定义路径模式

指定输入和输出目录：

```bash
# Linux/macOS
./video-merge-audio-reencode.sh /path/to/input /path/to/output

# Windows
video-merge-audio-reencode.bat "C:\Videos\raw" "C:\Videos\processed"
```

**注意：** 脚本会递归处理输入目录及其所有子文件夹中的视频文件。

## 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| (无) | 默认模式：处理脚本所在目录及所有子文件夹 | `./script.sh` |
| 输入目录 | 包含视频文件的源目录 | `/home/user/Videos/raw` |
| 输出目录 | 处理后视频的保存目录 | `/home/user/Videos/processed` |

## 使用场景示例

### 场景 1：快速处理单个文件夹的视频

**目录结构：**
```
我的视频/
├── video-merge-audio-reencode.sh  (或 .bat)
├── 电影1.mkv
├── 电影2.mov
└── 电影3.mp4
```

**操作：**
```bash
# 进入文件夹，直接运行脚本
cd "我的视频"
./video-merge-audio-reencode.sh  # Windows: video-merge-audio-reencode.bat
```

**结果：**
```
我的视频/
├── video-merge-audio-reencode.sh
├── 电影1.mkv
├── 电影2.mov
├── 电影3.mp4
└── output/                      ← 自动创建
    ├── 电影1.mp4
    ├── 电影2.mp4
    └── 电影3.mp4
```

### 场景 2：批量处理包含子文件夹的目录

**目录结构：**
```
Videos/
├── season-01/
│   ├── ep01.mkv
│   └── ep02.mkv
├── season-02/
│   ├── ep01.mkv
│   └── ep02.mkv
└── season-03/
    ├── ep01.mkv
    └── ep02.mkv
```

**操作：**
```bash
# 将脚本放入 Videos 文件夹中运行
cd Videos
./video-merge-audio-reencode.sh

# 或者指定路径
./video-merge-audio-reencode.sh /path/to/Videos /path/to/output
```

**结果：**
```
output/                          ← 所有视频统一输出到这里
├── ep01.mp4
├── ep02.mp4
├── ep01.mp4
├── ep02.mp4
├── ep01.mp4
└── ep02.mp4
```

### 场景 3：处理监控录像

**目录结构：**
```
CCTV/
├── 2024-01/
│   ├── cam01.mkv
│   └── cam02.mkv
├── 2024-02/
│   ├── cam01.mkv
│   └── cam02.mkv
└── 2024-03/
    ├── cam01.mkv
    └── cam02.mkv
```

**操作：**
```bash
# Linux/macOS
./video-merge-audio-reencode.sh /storage/CCTV /storage/compressed

# Windows
video-merge-audio-reencode.bat "D:\CCTV" "D:\compressed"
```

**注意：** 所有子文件夹中的视频文件都会被处理，输出的 MP4 文件会统一保存到输出目录中（平铺结构）。

## 编码策略

### 硬件编码器自动检测

脚本启动时会自动检测可用的硬件编码器并按优先级选择：

```
[INFO] 检测硬件编码器...
  [INFO]   NVIDIA NVENC (独显)
  [INFO] ✓ AMD AMF (独显) - [已选择]
  [INFO]   Intel Quick Sync (核显)
  [INFO]   CPU 软编码 (最慢)
```

**优先级：**
1. 独显编码器（NVIDIA NVENC、AMD AMF）- 最快
2. 核显编码器（Intel Quick Sync、VAAPI）
3. CPU 软编码（libx264）- 最后备选

### 比特率控制

脚本会自动检测源视频的比特率并选择最优编码策略：

#### 低比特率视频 (< 2000 kbps)
- 使用 **CRF 20** 模式（质量优先）
- 适合低分辨率视频

#### 高比特率视频 (≥ 2000 kbps)
- 使用 **VBR 两阶段编码**
- 参考源视频比特率
- 设置 maxrate 和 bufsize 控制质量波动

### 音频编码
- 格式：AAC
- 比特率：192 kbps
- 声道：立体声 (2 channels)

### 性能对比

| 编码器 | 平台 | 速度 (1080p) | 质量 |
|--------|------|--------------|------|
| NVIDIA NVENC | Windows/Linux | ~500 FPS | 优秀 |
| AMD AMF | Windows | ~400 FPS | 优秀 |
| Intel Quick Sync | Windows/Linux | ~300 FPS | 良好 |
| VideoToolbox | macOS | ~250 FPS | 优秀 |
| libx264 (CPU) | 全平台 | ~30-60 FPS | 最佳 |

**实际提升：** 处理 2 小时 1080p 视频从 2-4 小时缩短至 5-15 分钟！🚀

## 工作流程

```
输入目录扫描
    ↓
检测视频文件 (mkv/mov/mp4)
    ↓
分析音频轨道数量
    ↓
┌─────────────┬─────────────┐
│  单个音轨    │  多个音轨    │
│  直接使用    │  混音合并    │
└─────────────┴─────────────┘
    ↓
H.264 重新编码视频
    ↓
AAC 编码音频
    ↓
封装为 MP4 (FastStart)
    ↓
保存到输出目录
```

## 输出示例

```
[信息] 默认模式：处理当前目录及子文件夹
[信息] 输入目录: /home/user/Videos
[信息] 输出目录: /home/user/Videos/output

[信息] 依赖检查通过
[信息] 扫描视频文件...
[信息] 找到 6 个视频文件（包含子文件夹）

[INFO] 正在处理: video1.mkv
  检测到 2 个音频轨道
  源视频参考比特率: 3500 kbps
  使用混音滤镜合并 2 个音轨
  开始编码...
  完成: video1.mp4

[INFO] 正在处理: video2.mov
  检测到 1 个音频轨道
  开始编码...
  完成: video2.mp4

[INFO] 正在处理: video3.mp4
  检测到 3 个音频轨道
  源视频参考比特率: 1500 kbps
  使用混音滤镜合并 3 个音轨
  开始编码...
  完成: video3.mp4

===================================
[INFO] 处理完成！
  成功: 3
  失败: 0
  总计: 3
===================================
```

## 性能优化建议

1. **使用 SSD**：将输出目录放在 SSD 上可以显著提升编码速度
2. **多核处理**：FFmpeg 会自动利用多核 CPU
3. **预设调整**：编辑脚本中的 `-preset medium` 参数：
   - `ultrafast`: 最快速度，最低质量
   - `medium`: 平衡（默认）
   - `veryslow`: 最慢速度，最高质量

## 常见问题

### Q: Windows 下运行脚本出现中文乱码怎么办？
A: **Windows 批处理脚本（.bat）已改为全英文输出**，彻底避免编码问题。
- 如果需要中文界面，请使用 PowerShell 运行 `.sh` 版本脚本
- 或使用 Git Bash/WSL 运行 `.sh` 版本（包含中文支持）
- CMD 运行 .bat 文件将显示英文提示信息

### Q: 编码速度很慢怎么办？
A: 可以修改脚本中的 preset 参数，将 `medium` 改为 `fast` 或 `veryfast`。

### Q: 如何调整输出质量？
A: 修改 CRF 值（默认 23）：
- 更低质量（文件更小）：CRF 28
- 更高质量（文件更大）：CRF 18

### Q: 默认模式会处理子文件夹吗？
A: **会**。默认模式会递归处理当前目录及所有子文件夹中的视频文件。所有输出的 MP4 文件会统一保存到 output 目录中。

### Q: 如果只想处理当前目录，不处理子文件夹怎么办？
A: 目前脚本默认递归处理所有子文件夹。如果只想处理当前目录，可以将视频文件移动到一个不含子文件夹的目录中，或者使用自定义路径模式指定具体的子文件夹。

### Q: 能否批量处理多个目录？
A: 可以使用循环命令：
```bash
for dir in /path/to/*/; do
    ./video-merge-audio-reencode.sh "$dir" "/path/to/output/$(basename "$dir")"
done
```

## 许可证

MIT License - 详见项目根目录 LICENSE 文件

## 作者

RoL1n

## 贡献

欢迎提交 Issue 和 Pull Request！
