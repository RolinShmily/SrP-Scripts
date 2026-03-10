# SrP-Scripts

个人脚本集合，存放各种实用的小脚本。

## 简介

这个仓库用于存放我日常使用和编写的一些实用脚本。

所有脚本都支持跨平台使用（Windows、Linux、macOS）。

## 脚本列表

### video-merge-audio-reencode

视频批量处理脚本，支持跨平台运行。

**功能：**
- 自动扫描指定目录中的 mkv/mov/mp4 视频文件
- 将每个视频的所有音频轨道混音合并为一个音轨
- 使用 h.264 重新编码视频（智能参考源视频质量）
- 保持原视频的分辨率和帧率
- 统一输出为 MP4 格式

**平台支持：**
- Windows: `video-merge-audio-reencode.bat`
- Linux/macOS: `video-merge-audio-reencode.sh`

**使用方法：**
```bash
# Linux/macOS
cd video-merge-audio-reencode
./video-merge-audio-reencode.sh /path/to/input /path/to/output

# Windows
cd video-merge-audio-reencode
video-merge-audio-reencode.bat "C:\input" "C:\output"
```

**依赖：**
- FFmpeg (必装)

详见 [video-merge-audio-reencode/README.md](video-merge-audio-reencode/README.md)

## 目录结构

```
SrP-Scripts/
├── video-merge-audio-reencode/     # 视频处理脚本
│   ├── video-merge-audio-reencode.sh   # Linux/macOS 版本
│   ├── video-merge-audio-reencode.bat  # Windows 版本
│   └── README.md                        # 脚本详细说明
├── LICENSE                         # MIT 许可证
└── README.md                       # 本文件
```

## 许可证

本项目采用 MIT 许可证开源 - 详见 [LICENSE](LICENSE) 文件

## 作者

RoL1n

## 贡献

欢迎提交 Issue 和 Pull Request！
