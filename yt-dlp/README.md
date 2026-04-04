# yt-dlp 实用工具集

基于 [yt-dlp](https://github.com/yt-dlp/yt-dlp) 封装的 Python 脚本工具集，提供一键下载、自动转码和安装验证功能。

## 依赖

- Python 3.10+
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) — 视频下载核心（上游仓库）
- [ffmpeg](https://ffmpeg.org/) — 视频合并与转码

安装 yt-dlp 完整版：

```bash
pip install "yt-dlp[default]"
```

---

## 脚本说明

### verify_ytdlp.py — 安装完整性验证

检测 pip 安装的 yt-dlp 是否为完整版。pip 默认安装精简版，缺少部分可选依赖会导致部分功能不可用。

**用法：**

```bash
python verify_ytdlp.py
```

**检查项：**
- yt-dlp 版本与安装路径
- Python 版本与路径
- 可选依赖：`mutagen`（音频元数据）、`pycryptodomex`（加密流解密）、`websockets`（直播流）、`brotli`（压缩解码）、`certifi`（SSL 证书）、`curl_cffi`（TLS 指纹伪装）等
- 外部工具：`ffmpeg`
- 综合评定：完整版 / 部分完整 / 精简版

**输出示例：**

```
============================================================
  yt-dlp 完整性验证工具
============================================================

[ 核心信息 ]
  yt-dlp 版本:  2025.03.31
  安装路径:     ...\yt_dlp\__init__.py
  Python 版本:  3.13.2
  Python 路径:  ...\python.exe

[ 可选依赖检查 ]
  ✔ mutagen             1.47.0
    └─ 音频元数据（标题、艺术家、封面等）写入支持
  ...

[ 综合评定 ]
  可选依赖: 6/7 已安装
  核心依赖: 4/4 已安装
  评定结果: 🎉 完整版 — 所有核心依赖均已安装
```

如果检测到精简版，脚本会提示执行：

```bash
pip install "yt-dlp[default]"
```

---


### quick_grab.py — 快速获取视频

下载任意网站视频，自动确保输出为 H.264 + AAC 的 MP4 文件。

**特性：**
- 自动检测并使用 GPU 硬件加速（NVIDIA NVENC / AMD AMF / Intel QSV），无 GPU 回退 CPU
- 探测源视频码率，按源码率匹配目标画质，避免转码后文件暴涨
- 支持断点续传，网络中断后重新运行可从上次位置继续
- 内置失败重试（10 次重试 + 指数退避）

**基本用法：**

```bash
# 下载最高画质（自动转码为 H.264 MP4）
python quick_grab.py "https://www.youtube.com/watch?v=VIDEO_ID"

# 指定输出目录
python quick_grab.py "URL" -d D:/Downloads

# 下载 720P
python quick_grab.py "URL" -q 720

# 仅下载音频
python quick_grab.py "URL" --audio

# 下载中英字幕
python quick_grab.py "URL" --subtitle

# 下载整个播放列表
python quick_grab.py "URL" --playlist

# 自定义编码质量（CRF 越小质量越高，默认 23）
python quick_grab.py "URL" --crf 18 --preset slow

# 强制使用 CPU 编码（禁用 GPU 加速）
python quick_grab.py "URL" --no-gpu

# 指定输出文件名
python quick_grab.py "URL" -o "my_video.mp4"
```

**参数说明：**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `URL` | 视频 URL（必填） | — |
| `-d, --output-dir` | 输出目录 | 当前目录 |
| `-o, --output` | 输出文件名 | `视频标题.扩展名` |
| `-q, --quality` | 最高分辨率（如 720, 1080） | 不限 |
| `-a, --audio` | 仅下载音频 | 关闭 |
| `-p, --playlist` | 下载整个播放列表 | 关闭 |
| `-s, --subtitle` | 下载中英字幕 | 关闭 |
| `--crf` | H.264 质量值（0-51，越小越高） | 23 |
| `--preset` | 编码速度预设 | medium |
| `--no-gpu` | 禁用 GPU 加速 | 关闭 |

**转码流程：**

1. yt-dlp 下载视频（自动合并视频+音频流）
2. ffprobe 检测编码格式
3. 如果已经是 H.264 + AAC + MP4 → 跳过（无需转码）
4. 如果编码正确但容器非 MP4 → 仅 remux（无损，极快）
5. 如果需要转码 → 自动探测源码率，按源码率匹配目标画质：
   - **NVENC**：`-rc vbr -cq -b:v {源码率}k -maxrate {源码率}k`
   - **AMF/QSV**：类似 VBR 码率控制
   - **CPU**：高码率用 `-b:v` 码率模式，低/未知码率用 `-crf` 质量模式
   - 低码率（< 2000k）自动降低 CRF 至 20 以保画质

---

### quick_audio.py — 快速获取音频

下载任意网站音频，转为 AAC 编码的 M4A 文件，兼容 iPhone / Android / Windows / Mac / 车载等所有主流播放器。

**基本用法：**

```bash
# 下载音频，输出 AAC/M4A (192kbps)
python quick_audio.py "https://www.youtube.com/watch?v=VIDEO_ID"

# 指定输出目录
python quick_audio.py "URL" -d D:/Downloads

# 320kbps 高音质
python quick_audio.py "URL" -b 320

# 输出 MP3 格式（兼容极老旧设备）
python quick_audio.py "URL" --mp3

# 下载整个播放列表的音频
python quick_audio.py "URL" --playlist
```

**参数说明：**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `URL` | 音频/视频 URL（必填） | — |
| `-d, --output-dir` | 输出目录 | 当前目录 |
| `-o, --output` | 输出文件名 | `标题.m4a` |
| `-b, --bitrate` | 音频码率 (kbps) | 192 |
| `-p, --playlist` | 下载整个播放列表 | 关闭 |
| `--mp3` | 输出 MP3 格式 | 默认 M4A |

---
