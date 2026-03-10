# 视频处理脚本 (Windows PowerShell 版本)
# 功能：将指定目录中的视频文件的所有音频轨道混音合并，视频用h.264重新编码
# 作者：RoL1n
# 许可证：MIT

# 设置控制台编码为 UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

param(
    [string]$InputDir,
    [string]$OutputDir
)

# 显示使用说明
function Show-Usage {
    Write-Host "用法: .\video-merge-audio-reencode.ps1 [[-InputDir] 目录] [[-OutputDir] 目录]"
    Write-Host ""
    Write-Host "功能："
    Write-Host "  - 扫描输入目录中的 mkv/mov/mp4 视频文件（递归所有子文件夹）"
    Write-Host "  - 将每个视频的所有音频轨道混音合并为一个音轨"
    Write-Host "  - 使用 h.264 重新编码视频（智能参考源视频质量）"
    Write-Host "  - 保持原视频的分辨率和帧率"
    Write-Host "  - 输出为 MP4 格式到指定目录"
    Write-Host "  - 自动检测并使用硬件编码器（NVIDIA/AMD/Intel）"
    Write-Host ""
    Write-Host "使用方式："
    Write-Host "  1. 默认模式（推荐）"
    Write-Host "     将脚本放入视频文件夹中，直接运行："
    Write-Host "     .\video-merge-audio-reencode.ps1"
    Write-Host "     自动处理当前目录及所有子文件夹，输出到 'output' 文件夹"
    Write-Host ""
    Write-Host "  2. 自定义路径模式"
    Write-Host "     指定输入和输出目录："
    Write-Host "     .\video-merge-audio-reencode.ps1 -InputDir 'C:\Videos\raw' -OutputDir 'C:\Videos\processed'"
    Write-Host ""
    Write-Host "依赖："
    Write-Host "  - ffmpeg (需要添加到 PATH 环境变量)"
    Write-Host ""
    Write-Host "示例："
    Write-Host "  # 默认模式"
    Write-Host "  .\video-merge-audio-reencode.ps1"
    Write-Host ""
    Write-Host "  # 自定义路径（支持中文和空格）"
    Write-Host "  .\video-merge-audio-reencode.ps1 -InputDir 'E:\视频\电影' -OutputDir 'E:\视频\输出'"
    exit 1
}

# 检查依赖
function Test-Dependencies {
    Write-Host "[INFO] 检查依赖..." -ForegroundColor Green

    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
        Write-Host "[INFO] 依赖检查通过" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] 未找到 ffmpeg" -ForegroundColor Red
        Write-Host "请先安装 ffmpeg 并添加到 PATH 环境变量" -ForegroundColor Yellow
        Write-Host "下载地址: https://www.gyan.dev/ffmpeg/builds/" -ForegroundColor Cyan
        Read-Host "按回车键退出"
        exit 1
    }
}

# 检测硬件编码器
function Get-HardwareEncoder {
    Write-Host "[INFO] 检测硬件编码器..." -ForegroundColor Green

    $encoders = @()
    $selectedEncoder = "libx264"

    # 检测 NVIDIA NVENC
    $encoders += @{Name = "h264_nvenc"; Desc = "NVIDIA NVENC (独显)"}
    # 检测 AMD AMF
    $encoders += @{Name = "h264_amf"; Desc = "AMD AMF (独显)"}
    # 检测 Intel Quick Sync
    $encoders += @{Name = "h264_qsv"; Desc = "Intel Quick Sync (核显)"}
    # CPU 软编码
    $encoders += @{Name = "libx264"; Desc = "CPU 软编码 (最慢)"}

    # 测试每个编码器
    foreach ($enc in $encoders) {
        try {
            $null = ffmpeg -hide_banner -encoders 2>&1 | Select-String $enc.Name
            if ($?) {
                Write-Host ("  [INFO]   " + $enc.Desc) -ForegroundColor Cyan
                if ($selectedEncoder -eq "libx264") {
                    $selectedEncoder = $enc.Name
                }
            }
        } catch {
            # 忽略错误
        }
    }

    # 标记已选择的编码器
    Write-Host ("  [INFO] ✓ " + ($encoders | Where-Object { $_.Name -eq $selectedEncoder }).Desc + " - [已选择]") -ForegroundColor Green

    return $selectedEncoder
}

# 处理单个视频
function Process-Video {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [string]$Encoder
    )

    $filename = Split-Path $InputFile -Leaf
    Write-Host "[INFO] 正在处理: $filename" -ForegroundColor Green

    # 检测音频轨道数量
    $audioCount = ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 $InputFile 2>&1 | Measure-Object -Line | Select-Object -ExpandProperty Lines
    Write-Host "  检测到 $audioCount 个音频轨道"

    # 获取源视频比特率
    $sourceBitrate = ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 $InputFile 2>$null
    if ([string]::IsNullOrEmpty($sourceBitrate) -or $sourceBitrate -eq 0) {
        $targetBitrate = 0
    } else {
        $targetBitrate = [int]$sourceBitrate / 1000
        Write-Host "  源视频参考比特率: ${targetBitrate} kbps"
    }

    # 构建 ffmpeg 参数
    $videoParams = ""
    $crfValue = 23

    switch ($Encoder) {
        "h264_nvenc" {
            $videoParams = "-c:v h264_nvenc -preset p4 -rc vbr -cq $crfValue"
            if ($targetBitrate -ge 2000) {
                $videoParams = "-c:v h264_nvenc -preset p4 -rc vbr -b:v ${targetBitrate}k -maxrate ${targetBitrate}k -bufsize $($targetBitrate*2)k -cq $crfValue"
            }
        }
        "h264_amf" {
            $videoParams = "-c:v h264_amf -quality speed -rc vbr"
            if ($targetBitrate -ge 2000) {
                $videoParams = "-c:v h264_amf -quality speed -rc vbr -b:v ${targetBitrate}k -maxrate ${targetBitrate}k -bufsize $($targetBitrate*2)k"
            }
        }
        "h264_qsv" {
            $videoParams = "-c:v h264_qsv -preset medium -global_quality $crfValue"
            if ($targetBitrate -ge 2000) {
                $videoParams = "-c:v h264_qsv -preset medium -b:v ${targetBitrate}k -maxrate ${targetBitrate}k -bufsize $($targetBitrate*2)k -global_quality $crfValue"
            }
        }
        default {
            $videoParams = "-c:v libx264 -preset medium -crf $crfValue"
            if ($targetBitrate -ge 2000) {
                $videoParams = "-c:v libx264 -preset medium -b:v ${targetBitrate}k -maxrate ${targetBitrate}k -bufsize $($targetBitrate*2)k"
            }
        }
    }

    $audioParams = "-c:a aac -b:a 192k -ac 2"

    # 执行转换
    Write-Host "  开始编码..." -ForegroundColor Yellow

    $ffmpegArgs = @("-i", $InputFile)

    if ($audioCount -gt 1) {
        Write-Host "  使用混音滤镜合并 $audioCount 个音轨"
        $ffmpegArgs += "-filter_complex", "amix:inputs=$audioCount:duration=longest[a]", "-map", "0:v", "-map", "[a]"
    } else {
        $ffmpegArgs += "-map", "0"
    }

    $ffmpegArgs += $videoParams.Split(" ")
    $ffmpegArgs += $audioParams.Split(" ")
    $ffmpegArgs += "-movflags", "+faststart", "-y", $OutputFile

    # 运行 ffmpeg
    $process = Start-Process -FilePath "ffmpeg" -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -Wait

    # 检查输出文件
    if (Test-Path $OutputFile) {
        $fileSize = (Get-Item $OutputFile).Length
        if ($fileSize -gt 0) {
            Write-Host "  完成: $(Split-Path $OutputFile -Leaf)" -ForegroundColor Green
            return $true
        }
    }

    Write-Host "  [WARNING] 处理失败: $filename（输出文件未生成）" -ForegroundColor Yellow
    return $false
}

# ========== 主程序 ==========

# 智能参数处理
if ([string]::IsNullOrEmpty($InputDir) -and [string]::IsNullOrEmpty($OutputDir)) {
    # 默认模式：使用脚本所在目录
    $InputDir = Split-Path -Parent $PSScriptRoot
    $OutputDir = Join-Path $InputDir "output"

    Write-Host "[INFO] 默认模式：处理当前目录及子文件夹" -ForegroundColor Green
    Write-Host "[INFO] 输入目录: $InputDir"
    Write-Host "[INFO] 输出目录: $OutputDir"
    Write-Host ""
} elseif ([string]::IsNullOrEmpty($InputDir) -or [string]::IsNullOrEmpty($OutputDir)) {
    Show-Usage
} else {
    Write-Host "[INFO] 自定义路径模式" -ForegroundColor Green
    Write-Host "[INFO] 输入目录: $InputDir"
    Write-Host "[INFO] 输出目录: $OutputDir"
    Write-Host ""
}

# 检查依赖
Test-Dependencies

# 检测硬件编码器
$hwEncoder = Get-HardwareEncoder
Write-Host ""

# 验证输入目录
if (-not (Test-Path $InputDir)) {
    Write-Host "[ERROR] 输入目录不存在: $InputDir" -ForegroundColor Red
    Read-Host "按回车键退出"
    exit 1
}

# 创建输出目录
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
Write-Host "[INFO] 输出目录: $OutputDir" -ForegroundColor Green

# 查找视频文件（递归所有子文件夹）
Write-Host "[INFO] 扫描视频文件..." -ForegroundColor Green

$videoFiles = Get-ChildItem -Path $InputDir -Recurse -Include *.mkv, *.mov, *.mp4 -File | Where-Object { $_.DirectoryName -notlike "*\output" }

$totalFiles = $videoFiles.Count

if ($totalFiles -eq 0) {
    Write-Host "[ERROR] 未找到任何视频文件 (mkv/mov/mp4)" -ForegroundColor Red
    Read-Host "按回车键退出"
    exit 1
}

Write-Host "[INFO] 找到 $totalFiles 个视频文件" -ForegroundColor Green
Write-Host ""

# 处理每个视频文件
$successCount = 0
$failCount = 0

foreach ($videoFile in $videoFiles) {
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($videoFile.Name)
    $outputFile = Join-Path $OutputDir "$nameWithoutExt.mp4"

    if (Process-Video -InputFile $videoFile.FullName -OutputFile $outputFile -Encoder $hwEncoder) {
        $successCount++
    } else {
        $failCount++
    }

    Write-Host ""
}

# 总结
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "[INFO] 处理完成！" -ForegroundColor Green
Write-Host "  成功: $successCount"
Write-Host "  失败: $failCount"
Write-Host "  总计: $totalFiles"
Write-Host "===================================" -ForegroundColor Cyan
Read-Host "按回车键退出"
