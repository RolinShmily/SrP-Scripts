"""
验证 pip 安装的 yt-dlp 是否为完整版

yt-dlp 的完整功能依赖多个可选依赖包，pip 默认安装的是精简版。
通过 [default] 或 [curl-cffi] 等 extras 才会安装完整依赖。

用法:
    python verify_ytdlp.py
"""

import importlib
import io
import sys
import platform

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")


# (pip包名, import名, 用途描述)
# pip 包名和 import 名不同的包需要分别指定
OPTIONAL_DEPS: list[tuple[str, str, str]] = [
    # 核心可选依赖 (pip install yt-dlp[default])
    ("mutagen",        "mutagen",        "音频元数据（标题、艺术家、封面等）写入支持"),
    ("pycryptodomex",  "Cryptodome",     "部分加密视频流的解密支持"),
    ("websockets",     "websockets",     "WebSocket 协议直播流下载支持"),
    ("brotli",         "brotli",         "Brotli 压缩传输解码支持"),
    ("certifi",        "certifi",        "SSL 证书验证（Windows 移动版等需要）"),
    # 额外可选依赖
    ("curl_cffi",      "curl_cffi",      "curl_cffi TLS 指纹伪装（绕过部分 Cloudflare 防护）"),
    ("secretstorage",  "secretstorage",  "GNOME Keyring 凭据存储支持（Linux）"),
]

# 核心依赖索引（用于综合评定）
CORE_DEP_INDICES = [0, 1, 2, 3]  # mutagen, pycryptodomex, websockets, brotli


def check_dep(import_name: str) -> tuple[bool, str]:
    """检查单个依赖是否可用，返回 (是否已安装, 版本信息)"""
    try:
        mod = importlib.import_module(import_name)
        version = getattr(mod, "__version__", None)
        return True, version or "已安装（版本未知）"
    except ImportError:
        return False, "未安装"


def check_ytdlp_core() -> dict:
    """检查 yt-dlp 核心模块信息"""
    info = {}
    try:
        import yt_dlp
        info["version"] = yt_dlp.version.__version__
        info["install_path"] = yt_dlp.__file__
        info["python_version"] = platform.python_version()
        info["python_path"] = sys.executable
    except ImportError:
        info["installed"] = False
    return info


def check_ffmpeg() -> tuple[bool, str]:
    """检查 ffmpeg 是否可用"""
    import subprocess
    try:
        result = subprocess.run(
            ["ffmpeg", "-version"],
            capture_output=True, text=True, timeout=5,
        )
        if result.returncode == 0:
            first_line = result.stdout.strip().split("\n")[0]
            return True, first_line
        return False, "ffmpeg 执行失败"
    except FileNotFoundError:
        return False, "未找到 ffmpeg"
    except Exception as e:
        return False, f"检测出错: {e}"


def main():
    print("=" * 60)
    print("  yt-dlp 完整性验证工具")
    print("=" * 60)

    # --- 核心信息 ---
    print("\n[ 核心信息 ]")
    core = check_ytdlp_core()
    if "version" not in core:
        print("  ✗ yt-dlp 未安装！")
        return 1

    print(f"  yt-dlp 版本:  {core['version']}")
    print(f"  安装路径:     {core['install_path']}")
    print(f"  Python 版本:  {core['python_version']}")
    print(f"  Python 路径:  {core['python_path']}")

    # --- 可选依赖检查 ---
    print("\n[ 可选依赖检查 ]")
    results: list[tuple[str, str, str, bool, str]] = []  # pip_name, import_name, desc, ok, info

    for pip_name, import_name, desc in OPTIONAL_DEPS:
        ok, info = check_dep(import_name)
        results.append((pip_name, import_name, desc, ok, info))
        status = "✔" if ok else "✗"
        print(f"  {status} {pip_name:20s} {info}")
        print(f"    └─ {desc}")

    # --- FFmpeg 检查 ---
    print("\n[ 外部工具检查 ]")
    ok, info = check_ffmpeg()
    status = "✔" if ok else "✗"
    print(f"  {status} ffmpeg: {info}")

    # --- 综合评定 ---
    print("\n" + "=" * 60)
    print("  综合评定")
    print("=" * 60)

    total = len(OPTIONAL_DEPS)
    installed_count = sum(1 for r in results if r[3])
    core_installed = sum(1 for i in CORE_DEP_INDICES if results[i][3])
    core_total = len(CORE_DEP_INDICES)

    if core_installed == core_total:
        verdict = "完整版 — 所有核心依赖均已安装"
        emoji = "🎉"
    elif core_installed >= core_total // 2 + 1:
        verdict = "部分完整 — 核心依赖部分缺失，部分功能可能受限"
        emoji = "⚠️"
    else:
        verdict = "精简版 — 缺少大部分可选依赖，建议重新安装"
        emoji = "❌"

    print(f"\n  可选依赖: {installed_count}/{total} 已安装")
    print(f"  核心依赖: {core_installed}/{core_total} 已安装")
    print(f"  评定结果: {emoji} {verdict}")

    if core_installed < core_total:
        print(f"\n  💡 建议: 执行以下命令安装完整版依赖:")
        print(f"     pip install \"yt-dlp[default]\"")

    print()
    return 0 if core_installed == core_total else 1


if __name__ == "__main__":
    sys.exit(main())
