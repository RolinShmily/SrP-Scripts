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

## 安装 FFmpeg

### Linux
```bash
# Arch Linux
sudo pacman -S ffmpeg

# Ubuntu/Debian
sudo apt install ffmpeg

# Fedora
sudo dnf install ffmpeg
```

### macOS
```bash
brew install ffmpeg
```

### Windows
- **推荐**：使用 WSL (Windows Subsystem for Linux)
- **备选**：下载 [ffmpeg](https://www.gyan.dev/ffmpeg/builds/) 并添加到 PATH

**注意**：Windows Batch 脚本需要 ffmpeg 4.3 或更高版本以支持 NVENC 硬件加速。如果遇到编码器错误，请升级 ffmpeg 或使用 WSL + bash 脚本。

## 编码器优先级

脚本会自动检测并按优先级选择编码器：

1. NVIDIA NVENC (独显) - 最快
2. AMD AMF (独显)
3. Intel Quick Sync (核显)
4. VAAPI (Linux 核显)
5. VideoToolbox (macOS)
6. libx264 (CPU 软编码)

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

## 常见问题

### Windows 下 NVENC 编码失败
如果看到类似 `Cannot get the preset configuration` 或 `unsupported param` 错误，说明 ffmpeg 版本过旧。请：
1. 升级到 [最新版 ffmpeg](https://www.gyan.dev/ffmpeg/builds/)
2. 或使用 WSL + bash 脚本（推荐）

### 输出文件为空或编码失败
- 检查磁盘空间是否充足
- 查看控制台的错误信息
- 确认视频文件未损坏

## 许可证

MIT License

## 作者

RoL1n
