# SrP-Scripts

个人脚本集合，存放各种实用的小脚本。

## 🎯 特点

- ✅ **全平台支持**：Windows、Linux、macOS
- ✅ **开箱即用**：简单快捷，无需复杂配置
- ✅ **自动优化**：智能检测并使用最优硬件加速

## 📦 脚本列表

### 🎬 视频音频合并与重编码

**跨平台视频处理工具**，一键合并音轨并重新编码。

**核心功能：**
- 🔍 自动扫描视频文件（支持递归子文件夹）
- 🎵 合并所有音频轨道为一个
- ⚡ 自动使用最优硬件编码器（10-50倍加速）
- 🎬 输出标准 H.264 + MP4 格式
- 📐 智能参考源视频质量

**依赖：**
- ⚙️ FFmpeg（深度基于 FFmpeg）

**平台支持：**
- 💻 **Windows**: `.bat` 脚本
- 🐧 **Linux**: `.sh` 脚本
- 🍎 **macOS**: `.sh` 脚本

**快速开始：**
```bash
# Linux/macOS
./video-merge-audio-reencode.sh

# Windows
video-merge-audio-reencode.bat
```

📖 **[完整文档 →](video-merge-audio-reencode/README.md)**

## 📁 目录结构

```
SrP-Scripts/
├── video-merge-audio-reencode/     # 视频处理脚本
│   ├── video-merge-audio-reencode.sh   # Linux/macOS
│   ├── video-merge-audio-reencode.bat  # Windows
│   └── README.md                        # 详细文档
├── LICENSE                         # MIT 许可证
└── README.md                       # 本文件
```

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 👤 作者

**RoL1n**

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
