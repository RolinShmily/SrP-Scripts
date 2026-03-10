# 视频音频合并与重编码脚本

跨平台视频处理脚本，支持 Windows、Linux 和 macOS。

## 功能特性

- 🔍 **自动扫描**：扫描指定目录中的 mkv/mov/mp4 视频文件
- 🎵 **智能混音**：将每个视频的所有音频轨道混音合并为一个音轨
- 🎬 **H.264 编码**：使用 h.264 重新编码视频，智能参考源视频质量
- 📐 **保持参数**：自动保持原视频的分辨率和帧率
- 📦 **统一输出**：输出为标准 MP4 格式（带 FastStart，优化流媒体播放）
- 🎨 **彩色输出**：友好的彩色日志显示处理进度

## 系统要求

### Windows
- Windows 7 或更高版本
- [FFmpeg](https://www.gyan.dev/ffmpeg/builds/) (需要添加到 PATH 环境变量)

### Linux
- 任何主流 Linux 发行版
- FFmpeg (通过包管理器安装)

### macOS
- macOS 10.12 或更高版本
- [Homebrew](https://brew.sh/) + FFmpeg

## 安装 FFmpeg

### Windows
1. 下载 FFmpeg：[https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)
2. 解压到目录（如 `C:\ffmpeg`）
3. 将 `C:\ffmpeg\bin` 添加到系统 PATH 环境变量
4. 重启命令提示符，验证：`ffmpeg -version`

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

### Windows
```cmd
video-merge-audio-reencode.bat "C:\Videos\raw_movies" "C:\Videos\processed"
```

### Linux / macOS
```bash
# 添加执行权限 (首次使用)
chmod +x video-merge-audio-reencode.sh

# 运行脚本
./video-merge-audio-reencode.sh /path/to/videos /path/to/output
```

## 参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| 输入目录 | 包含视频文件的源目录 | `/home/user/Videos/raw` |
| 输出目录 | 处理后视频的保存目录 | `/home/user/Videos/processed` |

## 编码策略

脚本会自动检测源视频的比特率并选择最优编码策略：

### 低比特率视频 (< 2000 kbps)
- 使用 **CRF 20** 模式
- 质量优先，适合低分辨率视频

### 高比特率视频 (≥ 2000 kbps)
- 使用 **两阶段编码**
- 参考源视频比特率
- 设置 maxrate 和 bufsize 控制质量波动

### 音频编码
- 格式：AAC
- 比特率：192 kbps
- 声道：立体声 (2 channels)

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

## 示例

### 处理家庭视频
```bash
# Linux/macOS
./video-merge-audio-reencode.sh ~/Movies/raw ~/Movies/processed

# Windows
video-merge-audio-reencode.bat "C:\Movies\raw" "C:\Movies\processed"
```

### 批量处理监控录像
```bash
# Linux/macOS
./video-merge-audio-reencode.sh /storage/cctv/raw /storage/cctv/compressed

# Windows
video-merge-audio-reencode.bat "D:\CCTV\raw" "D:\CCTV\compressed"
```

## 输出示例

```
[INFO] 依赖检查通过
[INFO] 输出目录: /path/to/output
[INFO] 扫描视频文件...
[INFO] 找到 3 个视频文件

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

### Q: 编码速度很慢怎么办？
A: 可以修改脚本中的 preset 参数，将 `medium` 改为 `fast` 或 `veryfast`。

### Q: 如何调整输出质量？
A: 修改 CRF 值（默认 23）：
- 更低质量（文件更小）：CRF 28
- 更高质量（文件更大）：CRF 18

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
