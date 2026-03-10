#!/bin/bash

# 视频处理脚本 (Linux / macOS 版本)
# 功能：将指定目录中的视频文件的所有音频轨道混音合并，视频用h.264重新编码
# 作者：RoL1n
# 许可证：MIT
# 兼容性：Linux (GNU bash) / macOS (BSD bash)

set -e

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="Linux";;
        Darwin*)    OS="macOS";;
        MINGW*|MSYS*|CYGWIN*) OS="Windows";;
        *)          OS="Unknown";;
    esac
}

detect_os

# 颜色输出 (macOS 终端兼容)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# 打印使用说明
usage() {
    echo "用法: $0 [输入目录] [输出目录]"
    echo ""
    echo "功能："
    echo "  - 扫描输入目录中的 mkv/mov/mp4 视频文件"
    echo "  - 将每个视频的所有音频轨道混音合并为一个音轨"
    echo "  - 使用 h.264 重新编码视频（参考源视频质量）"
    echo "  - 保持原视频的分辨率和帧率"
    echo "  - 输出为 MP4 格式到指定目录"
    echo ""
    echo "使用方式："
    echo "  1. 默认模式（推荐）"
    echo "     将脚本放入视频文件夹中，直接运行："
    echo "     $0"
    echo "     自动处理当前目录及所有子文件夹，输出到 './output' 文件夹"
    echo ""
    echo "  2. 自定义路径模式"
    echo "     指定输入和输出目录："
    echo "     $0 /path/to/videos /path/to/output"
    echo ""
    echo "依赖："
    echo "  - ffmpeg"
    echo "  - ffprobe"
    echo ""
    echo "安装方法："
    if [ "$OS" = "macOS" ]; then
        echo "  macOS: brew install ffmpeg"
    elif [ "$OS" = "Linux" ]; then
        echo "  Arch: sudo pacman -S ffmpeg"
        echo "  Ubuntu/Debian: sudo apt install ffmpeg"
        echo "  Fedora: sudo dnf install ffmpeg"
        echo "  openSUSE: sudo zypper install ffmpeg"
    fi
    echo ""
    echo "示例："
    echo "  # 默认模式：处理当前目录及子文件夹"
    echo "  $0"
    echo ""
    echo "  # 自定义路径"
    echo "  $0 ~/Videos/raw ~/Videos/processed"
    exit 1
}

# 打印信息
info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$1"
}

warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
    exit 1
}

# 检查依赖
check_dependencies() {
    local missing_deps=()

    if ! command -v ffmpeg &> /dev/null; then
        missing_deps+=("ffmpeg")
    fi

    if ! command -v ffprobe &> /dev/null; then
        missing_deps+=("ffprobe")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo ""
        error "缺少依赖: ${missing_deps[*]}"
    fi

    info "依赖检查通过"
}

# 验证目录
validate_directories() {
    local input_dir="$1"
    local output_dir="$2"

    if [ ! -d "$input_dir" ]; then
        error "输入目录不存在: $input_dir"
    fi

    # 创建输出目录（如果不存在）
    mkdir -p "$output_dir"
    info "输出目录: $output_dir"
}

# 获取视频文件的音频轨道数量
get_audio_track_count() {
    local video_file="$1"
    local count

    count=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$video_file" | wc -l)

    echo "$count"
}

# 获取视频的比特率（用于参考质量）
get_video_bitrate() {
    local video_file="$1"
    local bitrate

    bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null || echo "0")

    # 如果获取不到，尝试从整体比特率估算
    if [ "$bitrate" = "0" ] || [ -z "$bitrate" ]; then
        local total_bitrate
        total_bitrate=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null || echo "0")
        # 估算视频比特率为总比特率的 80%
        bitrate=$((total_bitrate * 80 / 100))
    fi

    echo "$bitrate"
}

# 处理单个视频文件
process_video() {
    local input_file="$1"
    local output_file="$2"
    local filename
    filename=$(basename "$input_file")

    info "正在处理: $filename"

    # 获取音频轨道数量
    local audio_count
    audio_count=$(get_audio_track_count "$input_file")

    info "  检测到 $audio_count 个音频轨道"

    # 获取源视频比特率作为参考
    local source_bitrate
    source_bitrate=$(get_video_bitrate "$input_file")

    # 计算目标比特率（h.264 编码，保留 10% 余量）
    local target_bitrate="0"
    if [ "$source_bitrate" != "0" ] && [ -n "$source_bitrate" ]; then
        target_bitrate=$((source_bitrate / 1000))  # 转换为 kbps
        info "  源视频参考比特率: ${target_bitrate} kbps"
    fi

    # 音频处理滤镜
    local audio_filter=""
    if [ "$audio_count" -gt 1 ]; then
        # 多个音轨：使用 amix 滤镜混音
        audio_filter="amix=inputs=$audio_count:duration=longest[a]"
        info "  使用混音滤镜合并 $audio_count 个音轨"
    fi

    # 构建 ffmpeg 参数
    local video_params="-c:v libx264 -preset medium -crf 23"
    if [ "$target_bitrate" != "0" ]; then
        # 如果源视频比特率较低，使用 CRF 模式；如果较高，使用比特率控制
        if [ "$target_bitrate" -lt 2000 ]; then
            # 低比特率视频，使用较低的 CRF 值
            video_params="-c:v libx264 -preset medium -crf 20"
        else
            # 高比特率视频，使用两阶段编码
            local bufsize=$((target_bitrate * 2))
            video_params="-c:v libx264 -preset medium -b:v ${target_bitrate}k -maxrate ${target_bitrate}k -bufsize ${bufsize}k"
        fi
    fi

    # 音频参数
    local audio_params="-c:a aac -b:a 192k -ac 2"

    # 执行转换
    info "  开始编码..."

    # 直接执行 ffmpeg 命令，将进度输出到 stderr 以显示实时进度
    if [ -n "$audio_filter" ]; then
        # 有音频滤镜
        ffmpeg -i "$input_file" \
            -filter_complex "$audio_filter" \
            -map 0:v \
            -map "[a]" \
            $video_params \
            $audio_params \
            -movflags +faststart \
            -y "$output_file" < /dev/null
    else
        # 没有音频滤镜（单个音轨）
        ffmpeg -i "$input_file" \
            $video_params \
            $audio_params \
            -movflags +faststart \
            -y "$output_file" < /dev/null
    fi

    # 检查输出文件是否真的生成
    if [ -f "$output_file" ] && [ -s "$output_file" ]; then
        info "  完成: $(basename "$output_file")"
        return 0
    else
        warn "  处理失败: $filename（输出文件未生成）"
        return 1
    fi
}

# 主函数
main() {
    local input_dir=""
    local output_dir=""

    # 智能参数处理
    if [ $# -eq 0 ]; then
        # 默认模式：使用脚本所在目录
        input_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        output_dir="${input_dir}/output"

        info "默认模式：处理当前目录及子文件夹"
        info "输入目录: $input_dir"
        info "输出目录: $output_dir"
        echo ""

    elif [ $# -eq 2 ]; then
        # 自定义路径模式
        input_dir="$1"
        output_dir="$2"

        info "自定义路径模式"
        info "输入目录: $input_dir"
        info "输出目录: $output_dir"
        echo ""

    else
        # 参数数量错误
        usage
    fi

    # 检查依赖
    check_dependencies

    # 验证目录
    validate_directories "$input_dir" "$output_dir"

    # 查找视频文件（递归所有子文件夹）
    info "扫描视频文件..."
    local video_files=()
    while IFS= read -r -d '' file; do
        video_files+=("$file")
    done < <(find "$input_dir" -type f \( -iname "*.mkv" -o -iname "*.mov" -o -iname "*.mp4" \) -print0)

    local total_files=${#video_files[@]}

    if [ $total_files -eq 0 ]; then
        error "未找到任何视频文件 (mkv/mov/mp4)"
    fi

    info "找到 $total_files 个视频文件"
    echo ""

    # 处理每个视频文件
    local success_count=0
    local fail_count=0

    for video_file in "${video_files[@]}"; do
        local filename
        filename=$(basename "$video_file")
        local name_without_ext="${filename%.*}"
        local output_file="$output_dir/${name_without_ext}.mp4"

        if process_video "$video_file" "$output_file"; then
            ((success_count++))
        else
            ((fail_count++))
        fi

        echo ""
    done

    # 总结
    echo "==================================="
    info "处理完成！"
    echo "  成功: $success_count"
    echo "  失败: $fail_count"
    echo "  总计: $total_files"
    echo "==================================="
}

# 运行主函数
main "$@"
