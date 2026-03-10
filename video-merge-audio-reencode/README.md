# 视频音频合并与重编码脚本

跨平台视频处理脚本，将视频的所有音频轨道合并，并重新编码为 H.264。

## 功能

- 扫描当前目录下的 mkv/mov/mp4 视频文件（递归子文件夹）
- 合并所有音频轨道为一个
- 自动检测并使用最优编码器（优先独显）
- 重新编码视频为 H.264（参考源视频质量）
- 输出 MP4 到 `output` 文件夹

## 快速开始

### Linux / macOS

```bash
# 1. 下载脚本到视频文件夹
cd /path/to/your/videos
curl -LJO https://raw.githubusercontent.com/RolinShmily/SrP-Scripts/main/video-merge-audio-reencode/video-merge-audio-reencode.sh
chmod +x video-merge-audio-reencode.sh

# 2. 运行
./video-merge-audio-reencode.sh
```

### Windows (推荐 WSL)

```bash
# 1. 在 WSL 中安装 ffmpeg
sudo apt update && sudo apt install ffmpeg

# 2. 下载并运行脚本
cd "/mnt/e/你的视频文件夹"
curl -LJO https://raw.githubusercontent.com/RolinShmily/SrP-Scripts/main/video-merge-audio-reencode/video-merge-audio-reencode.sh
chmod +x video-merge-audio-reencode.sh
./video-merge-audio-reencode.sh
```

### Windows (Batch)

```batch
REM 1. 下载脚本到视频文件夹
REM 访问：https://raw.githubusercontent.com/RolinShmily/SrP-Scripts/main/video-merge-audio-reencode/video-merge-audio-reencode.bat
REM 保存为：video-merge-audio-reencode.bat

REM 2. 双击运行
video-merge-audio-reencode.bat
```

## 硬件加速配置

### Windows

#### 方案 1：使用 Batch 脚本（推荐）

直接运行 `.bat` 脚本即可自动使用硬件加速：

- **NVIDIA**：自动使用 NVENC
- **AMD**：自动使用 AMF
- **Intel**：自动使用 Quick Sync

#### 方案 2：WSL（有限支持）

⚠️ **限制**：WSL 环境下无法直接访问 GPU 硬件加速

**问题**：
- WSL2 运行在虚拟机中，默认无法访问 Windows 的 GPU
- 即使 Windows 已安装 GPU 驱动，WSL 中的 ffmpeg 也无法使用硬件编码

**解决方案**：

1. **推荐**：直接在 Windows 下使用 `.bat` 脚本
2. **备选**：在 WSL 中调用 Windows 的 ffmpeg（需要修改脚本）
3. **现状**：使用 CPU 软编码（慢但稳定）

### Linux

#### Intel 核显 (UHD Graphics / Iris Xe)

**安装驱动**：

```bash
# Arch Linux / Manjaro
sudo pacman -S intel-media-driver libva-utils

# Ubuntu / Debian
sudo apt install intel-media-va-driver-non-free vainfo

# Fedora
sudo dnf install intel-media-driver libva-utils
```

**验证安装**：

```bash
# 检查 VAAPI
vainfo

# 测试编码器
ffmpeg -f lavfi -i nullsrc=s=100x100:d=1 -t 1 -c:v h264_vaapi -f null -
```

#### AMD 核显/独显

**安装驱动**：

```bash
# Arch Linux / Manjaro
sudo pacman -S mesa libva-utils

# Ubuntu / Debian
sudo apt install mesa-vdpau-drivers vainfo

# Fedora
sudo dnf install mesa-libVA-utils
```

**验证安装**：

```bash
# 检查 VAAPI
vainfo
```

#### NVIDIA 独显

**安装驱动**：

```bash
# Arch Linux / Manjaro
sudo pacman -S nvidia

# Ubuntu / Debian
sudo apt install nvidia-driver-535

# Fedora
sudo dnf install akmod-nvidia
```

**验证安装**：

```bash
# 检查 NVENC
ffmpeg -hide_banner -encoders | grep h264_nvenc

# 测试编码器
ffmpeg -f lavfi -i nullsrc=s=100x100:d=1 -t 1 -c:v h264_nvenc -f null -
```

### macOS

**安装 ffmpeg**：

```bash
# 使用 Homebrew
brew install ffmpeg

# 确保支持 VideoToolbox
brew reinstall ffmpeg --with-videosystem
```

**验证安装**：

```bash
# 检查 VideoToolbox
ffmpeg -hide_banner -encoders | grep h264_videotoolbox

# 测试编码器
ffmpeg -f lavfi -i nullsrc=s=100x100:d=1 -t 1 -c:v h264_videotoolbox -f null -
```

## 编码器优先级

脚本会自动检测并按优先级选择编码器：

### Linux
1. NVIDIA NVENC (独显) - 最快
2. AMD AMF (独显)
3. Intel Quick Sync (核显)
4. VAAPI (核显)
5. libx264 (CPU 软编码)

### macOS
1. VideoToolbox (硬件加速)
2. libx264 (CPU 软编码)

### Windows (Batch)
1. NVIDIA NVENC (独显)
2. AMD AMF (独显)
3. Intel Quick Sync (核显)
4. libx264 (CPU 软编码)

### Windows (WSL)
- 仅支持 CPU 软编码 (libx264)

## 输出示例

```
[INFO] 输入目录: /home/user/Videos
[INFO] 输出目录: /home/user/Videos/output

[INFO] 依赖检查通过
[INFO] 检测编码器...
  ✓ NVIDIA NVENC (独显)

[INFO] 扫描视频文件...
[INFO] 找到 3 个视频文件

[INFO] 处理: video1.mkv
  音频轨道: 2
  源比特率: 3500 kbps
  编码中...
  ✓ 完成

[INFO] 处理: video2.mov
  音频轨道: 1
  源比特率: 2500 kbps
  编码中...
  ✓ 完成

===================================
[INFO] 处理完成！
  成功: 2
  失败: 0
  总计: 2
===================================
```

## 性能对比

| 编码器 | 平台 | 速度 (1080p) | 质量 |
|--------|------|--------------|------|
| NVIDIA NVENC | Windows/Linux | ~500 FPS | 优秀 |
| AMD AMF | Windows | ~400 FPS | 优秀 |
| Intel Quick Sync | Windows/Linux | ~300 FPS | 良好 |
| VideoToolbox | macOS | ~250 FPS | 优秀 |
| VAAPI | Linux | ~200 FPS | 良好 |
| libx264 (CPU) | 全平台 | ~30-60 FPS | 最佳 |

**实际提升**：处理 2 小时 1080p 视频从 2-4 小时缩短至 5-15 分钟！

## 常见问题

### Linux 下检测到编码器但使用失败

**症状**：显示 "Using NVIDIA NVENC" 但编码失败

**原因**：缺少驱动或驱动版本过旧

**解决**：参考上面的"硬件加速配置"章节安装对应驱动

### WSL 下无法使用硬件加速

**症状**：总是显示 "Using CPU (libx264)"

**原因**：WSL 环境无法直接访问 Windows 的 GPU

**解决**：
1. 推荐使用 Windows `.bat` 脚本
2. 或配置 WSL2 GPU 直通（需要 Windows 11）

### Windows 下 NVENC 编码失败

**症状**：`Cannot get the preset configuration` 或 `unsupported param` 错误

**原因**：ffmpeg 版本过旧

**解决**：
1. 升级到 [最新版 ffmpeg](https://www.gyan.dev/ffmpeg/builds/)
2. 或使用 WSL + bash 脚本

### macOS 下无法使用 VideoToolbox

**症状**：检测不到 h264_videotoolbox 编码器

**原因**：ffmpeg 编译时未包含 VideoToolbox 支持

**解决**：
```bash
brew reinstall ffmpeg --with-videosystem
```

### 输出文件为空或编码失败

- 检查磁盘空间是否充足
- 查看控制台的完整错误信息
- 确认视频文件未损坏

## 许可证

MIT License

## 作者

RoL1n
