#!/bin/bash

# Video Processing Script (Linux / macOS)
# Merge audio tracks and re-encode video to H.264
# Author: RoL1n
# License: MIT

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="$SCRIPT_DIR"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }

info "Input directory: $INPUT_DIR"
info "Output directory: $OUTPUT_DIR"
echo ""

# Check dependencies
if ! command -v ffmpeg &> /dev/null; then
    echo "[ERROR] ffmpeg not found"
    echo "Install: sudo apt install ffmpeg (Linux) or brew install ffmpeg (macOS)"
    exit 1
fi

info "Dependencies OK"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Find video files (excluding output folder)
info "Scanning video files..."
mapfile -t video_files < <(find "$INPUT_DIR" -type f \( -iname "*.mkv" -o -iname "*.mov" -o -iname "*.mp4" \) -not -path "*/output/*")

total_files=${#video_files[@]}

if [ $total_files -eq 0 ]; then
    echo "[ERROR] No video files found"
    exit 1
fi

info "Found $total_files video file(s)"
echo ""

# Detect hardware encoder
hw_encoder="libx264"
info "Detecting encoder..."

if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_nvenc"; then
    if ffmpeg -f lavfi -i nullsrc=s=100x100:d=1 -t 1 -c:v h264_nvenc -f null - 2>/dev/null; then
        hw_encoder="h264_nvenc"
        info "  Using: NVIDIA NVENC"
    fi
fi

if [ "$hw_encoder" = "libx264" ]; then
    if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_amf"; then
        if ffmpeg -f lavfi -i nullsrc=s=100x100:d=1 -t 1 -c:v h264_amf -f null - 2>/dev/null; then
            hw_encoder="h264_amf"
            info "  Using: AMD AMF"
        fi
    fi
fi

if [ "$hw_encoder" = "libx264" ]; then
    if ffmpeg -hide_banner -encoders 2>/dev/null | grep -q "h264_qsv"; then
        if ffmpeg -f lavfi -i nullsrc=s=100x100:d=1 -t 1 -c:v h264_qsv -f null - 2>/dev/null; then
            hw_encoder="h264_qsv"
            info "  Using: Intel Quick Sync"
        fi
    fi
fi

if [ "$hw_encoder" = "libx264" ]; then
    info "  Using: CPU (libx264)"
fi

echo ""

# Process videos
success_count=0
fail_count=0

for video_file in "${video_files[@]}"; do
    filename=$(basename "$video_file")
    name_without_ext="${filename%.*}"
    output_file="$OUTPUT_DIR/${name_without_ext}.mp4"

    info "Processing: $filename"

    # Get audio count
    audio_count=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$video_file" | wc -l)
    echo "  Audio tracks: $audio_count"

    # Get bitrate
    source_bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null || echo "0")
    if [ "$source_bitrate" = "0" ] || [ -z "$source_bitrate" ]; then
        total_bitrate=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null || echo "0")
        source_bitrate=$((total_bitrate * 80 / 100))
    fi

    target_bitrate=0
    if [ "$source_bitrate" != "0" ] && [ -n "$source_bitrate" ]; then
        target_bitrate=$((source_bitrate / 1000))
        echo "  Source bitrate: ${target_bitrate} kbps"
    fi

    # Build encoding parameters
    crf_value="23"
    if [ "$target_bitrate" != "0" ] && [ "$target_bitrate" -lt 2000 ]; then
        crf_value="20"
    fi

    case "$hw_encoder" in
        "h264_nvenc")
            if [ "$target_bitrate" -gt 0 ]; then
                bufsize=$((target_bitrate * 2))
                video_params="-c:v h264_nvenc -preset fast -rc vbr -b:v ${target_bitrate}k -maxrate ${target_bitrate}k -bufsize ${bufsize}k -cq $crf_value"
            else
                video_params="-c:v h264_nvenc -preset fast -rc vbr -cq $crf_value"
            fi
            ;;
        "h264_amf")
            if [ "$target_bitrate" -gt 0 ]; then
                bufsize=$((target_bitrate * 2))
                video_params="-c:v h264_amf -quality speed -rc vbr -b:v ${target_bitrate}k -maxrate ${target_bitrate}k -bufsize ${bufsize}k"
            else
                video_params="-c:v h264_amf -quality speed -rc vbr"
            fi
            ;;
        "h264_qsv")
            if [ "$target_bitrate" -gt 0 ]; then
                bufsize=$((target_bitrate * 2))
                video_params="-c:v h264_qsv -preset medium -b:v ${target_bitrate}k -maxrate ${target_bitrate}k -bufsize ${bufsize}k -global_quality $crf_value"
            else
                video_params="-c:v h264_qsv -preset medium -global_quality $crf_value"
            fi
            ;;
        *)
            if [ "$target_bitrate" -ge 2000 ]; then
                bufsize=$((target_bitrate * 2))
                video_params="-c:v libx264 -preset medium -b:v ${target_bitrate}k -maxrate ${target_bitrate}k -bufsize ${bufsize}k"
            else
                video_params="-c:v libx264 -preset medium -crf $crf_value"
            fi
            ;;
    esac

    audio_params="-c:a aac -b:a 192k -ac 2"

    echo "  Encoding..."

    # Execute conversion
    if [ "$audio_count" -gt 1 ]; then
        ffmpeg -i "$video_file" \
            -filter_complex "amix=inputs=$audio_count:duration=longest[a]" \
            -map 0:v -map "[a]" \
            $video_params $audio_params \
            -movflags +faststart \
            -y "$output_file" </dev/null
    else
        ffmpeg -i "$video_file" \
            $video_params $audio_params \
            -movflags +faststart \
            -y "$output_file" </dev/null
    fi

    # Check output
    if [ -f "$output_file" ] && [ -s "$output_file" ]; then
        echo "  Done"
        ((success_count++))
    else
        echo "  Failed"
        ((fail_count++))
    fi

    echo ""
done

# Summary
echo "==================================="
info "Processing completed!"
echo "  Success: $success_count"
echo "  Failed: $fail_count"
echo "  Total: $total_files"
echo "==================================="
