"""
快速获取音频 - 使用 yt-dlp 下载任意网站音频，转为 AAC 编码的 M4A 文件

输出 M4A (AAC) — 兼容 iPhone / Android / Windows / Mac / 车载 / 所有主流播放器。
可选 --mp3 输出 MP3 格式以兼容极老旧设备。

用法:
    python quick_audio.py <URL>
    python quick_audio.py <URL> -d D:/Downloads
    python quick_audio.py <URL> -b 320       # 320kbps 高音质
    python quick_audio.py <URL> --mp3         # 输出 MP3 格式
"""

import argparse
import io
import os
import subprocess
import sys

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def _progress_hook(d: dict):
    """yt-dlp 下载进度回调"""
    if d["status"] == "downloading":
        pct = d.get("_percent_str", "?")
        spd = d.get("_speed_str", "?")
        eta = d.get("_eta_str", "?")
        print(f"\r  下载中: {pct} | 速度: {spd} | 剩余: {eta}", end="", flush=True)
    elif d["status"] == "finished":
        print("\n  下载完成，正在处理音频...")


def _find_file(ydl, info: dict) -> str | None:
    """定位 yt-dlp 实际输出的文件"""
    expected = ydl.prepare_filename(info)
    if os.path.isfile(expected):
        return expected
    base, _ = os.path.splitext(expected)
    for ext in (".m4a", ".mp3", ".ogg", ".opus", ".webm", ".wav", ".flac", ".wma", ".aac"):
        if os.path.isfile(base + ext):
            return base + ext
    return None


def _probe_audio_codec(filepath: str) -> str:
    """检测音频编码格式"""
    result = subprocess.run(
        ["ffprobe", "-v", "error",
         "-select_streams", "a:0",
         "-show_entries", "stream=codec_name",
         "-of", "csv=p=0", filepath],
        capture_output=True, text=True, timeout=10,
        encoding="utf-8", errors="replace",
    )
    return result.stdout.strip() or "unknown"


def _convert(input_path: str, bitrate: int = 192, output_mp3: bool = False) -> bool:
    """转码音频为 AAC/M4A 或 MP3"""
    base, _ = os.path.splitext(input_path)
    target_ext = ".mp3" if output_mp3 else ".m4a"
    output_path = base + "_tmp" + target_ext

    if output_mp3:
        codec = "libmp3lame"
        quality_arg = ["-b:a", f"{bitrate}k"]
        print(f"    → 转码为 MP3 ({bitrate}kbps)...")
    else:
        codec = "aac"
        quality_arg = ["-b:a", f"{bitrate}k"]
        print(f"    → 转码为 AAC/M4A ({bitrate}kbps)...")

    cmd = [
        "ffmpeg", "-i", input_path,
        "-c:a", codec, *quality_arg,
        "-movflags", "+faststart",
        "-y", output_path,
    ]
    result = subprocess.run(cmd)

    if result.returncode == 0 and os.path.isfile(output_path):
        final_path = base + target_ext
        os.replace(output_path, final_path)
        # 清理原始文件
        if os.path.isfile(input_path) and input_path != final_path:
            os.remove(input_path)
        return True

    if os.path.isfile(output_path):
        os.remove(output_path)
    return False


# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------

def grab_audio(url: str, output_dir: str = ".", output_name: str | None = None,
               bitrate: int = 192, playlist: bool = False,
               output_mp3: bool = False) -> int:
    """下载音频并转为 AAC/M4A 或 MP3"""
    try:
        import yt_dlp
    except ImportError:
        print("错误: 未安装 yt-dlp，请先执行 pip install yt-dlp")
        return 1

    os.makedirs(output_dir, exist_ok=True)

    target_ext = ".mp3" if output_mp3 else ".m4a"
    outtmpl = (os.path.join(output_dir, output_name) if output_name
               else os.path.join(output_dir, "%(title)s.%(ext)s"))

    ydl_opts: dict = {
        "outtmpl": outtmpl,
        "format": "bestaudio/best",
        "progress_hooks": [_progress_hook],
        # 断点续传 & 重试
        "continuedl": True,
        "retries": 10,
        "fragment_retries": 10,
        "file_access_retries": 10,
        "retry_sleep_functions": {"http": 5, "fragment": 5, "file_access": 3},
    }

    if not playlist:
        ydl_opts["noplaylist"] = True

    target_format = "MP3" if output_mp3 else "AAC/M4A"
    print(f"\n正在获取音频 ({target_format}, {bitrate}kbps): {url}\n")

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=True)

    if info is None:
        print("错误: 无法获取音频信息")
        return 1

    # 收集条目
    if "entries" in info:
        entries = [e for e in info["entries"] if e]
    else:
        entries = [info]

    # 目标编码
    target_codec = "mp3" if output_mp3 else "aac"

    print(f"\n[ 音频检查 ]")
    for entry in entries:
        filepath = _find_file(ydl, entry)
        if not filepath:
            print(f"  ⚠ 未找到文件: {entry.get('title', '?')}")
            continue

        name = os.path.basename(filepath)
        codec = _probe_audio_codec(filepath)
        _, ext = os.path.splitext(filepath)
        is_target = (codec == target_codec and ext.lower() == target_ext)

        print(f"  {name}")
        print(f"    编码: {codec}")

        if is_target:
            print(f"    ✓ 已是目标格式 ({target_codec}{target_ext})，跳过")
        else:
            _convert(filepath, bitrate=bitrate, output_mp3=output_mp3)
            print(f"    ✓ 转码完成 → {target_codec}{target_ext}")

    print("\n全部完成!")
    return 0


def main():
    p = argparse.ArgumentParser(
        description="快速获取音频 - 下载任意网站音频 (AAC/M4A 或 MP3)",
    )
    p.add_argument("url", help="音频/视频 URL")
    p.add_argument("-d", "--output-dir", default=".", help="输出目录 (默认: 当前目录)")
    p.add_argument("-o", "--output", help="输出文件名")
    p.add_argument("-b", "--bitrate", type=int, default=192,
                   help="音频码率 kbps (默认: 192, 建议: 128/192/256/320)")
    p.add_argument("-p", "--playlist", action="store_true", help="下载整个播放列表")
    p.add_argument("--mp3", action="store_true",
                   help="输出 MP3 格式 (默认: AAC/M4A)")
    args = p.parse_args()

    sys.exit(grab_audio(
        url=args.url,
        output_dir=args.output_dir,
        output_name=args.output,
        bitrate=args.bitrate,
        playlist=args.playlist,
        output_mp3=args.mp3,
    ))


if __name__ == "__main__":
    main()
