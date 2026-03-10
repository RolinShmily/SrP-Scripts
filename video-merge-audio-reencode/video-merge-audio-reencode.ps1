# Video Processing Script (Windows PowerShell Version)
# Merge all audio tracks and re-encode video to H.264
# Supports Chinese paths and spaces perfectly
# Author: RoL1n
# License: MIT

# Set console encoding to UTF-8
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # Ignore errors in older PowerShell versions
}

# Script parameters (with validation)
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "[WARNING] PowerShell version 3.0 or higher recommended" -ForegroundColor Yellow
    Write-Host "[INFO] Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
}

param(
    [Parameter(Mandatory=$false)]
    [string]$InputDir = "",

    [Parameter(Mandatory=$false)]
    [string]$OutputDir = ""
)

# Show usage
function Show-Usage {
    Write-Host "Usage: .\video-merge-audio-reencode.ps1 [[-InputDir] directory] [[-OutputDir] directory]"
    Write-Host ""
    Write-Host "Features:"
    Write-Host "  - Scan mkv/mov/mp4 video files (recursive all subfolders)"
    Write-Host "  - Mix all audio tracks into one"
    Write-Host "  - Re-encode video to H.264 (smart quality reference)"
    Write-Host "  - Keep original resolution and frame rate"
    Write-Host "  - Auto detect and use hardware encoder (NVIDIA/AMD/Intel)"
    Write-Host "  - Output as MP4 format"
    Write-Host ""
    Write-Host "Usage modes:"
    Write-Host "  1. Default mode (recommended)"
    Write-Host "     Place script in video folder and run:"
    Write-Host "     .\video-merge-audio-reencode.ps1"
    Write-Host ""
    Write-Host "  2. Custom path mode"
    Write-Host "     .\video-merge-audio-reencode.ps1 -InputDir 'C:\Videos\raw' -OutputDir 'C:\Videos\processed'"
    Write-Host ""
    Write-Host "Dependencies:"
    Write-Host "  - ffmpeg (must be added to PATH environment variable)"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  # Default mode"
    Write-Host "  .\video-merge-audio-reencode.ps1"
    Write-Host ""
    Write-Host "  # Custom path (supports Chinese and spaces)"
    Write-Host "  .\video-merge-audio-reencode.ps1 -InputDir 'E:\Videos\test' -OutputDir 'E:\Videos\output'"
    exit 1
}

# Check dependencies
function Test-Dependencies {
    Write-Host "[INFO] Checking dependencies..." -ForegroundColor Green

    try {
        $null = Get-Command ffmpeg -ErrorAction Stop
        Write-Host "[INFO] Dependencies check passed" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] ffmpeg not found" -ForegroundColor Red
        Write-Host "Please install ffmpeg and add to PATH environment variable" -ForegroundColor Yellow
        Write-Host "Download: https://www.gyan.dev/ffmpeg/builds/" -ForegroundColor Cyan
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Detect hardware encoder
function Get-HardwareEncoder {
    Write-Host "[INFO] Detecting hardware encoders..." -ForegroundColor Green

    $encoders = @()
    $selectedEncoder = "libx264"

    # Detect NVIDIA NVENC
    $encoders += @{Name = "h264_nvenc"; Desc = "NVIDIA NVENC (dedicated GPU)"}
    # Detect AMD AMF
    $encoders += @{Name = "h264_amf"; Desc = "AMD AMF (dedicated GPU)"}
    # Detect Intel Quick Sync
    $encoders += @{Name = "h264_qsv"; Desc = "Intel Quick Sync (integrated GPU)"}
    # CPU software encoding
    $encoders += @{Name = "libx264"; Desc = "CPU software encoding (slowest)"}

    # Test each encoder
    foreach ($enc in $encoders) {
        try {
            $result = ffmpeg -hide_banner -encoders 2>&1 | Select-String $enc.Name
            if ($result) {
                Write-Host ("  [INFO]   " + $enc.Desc) -ForegroundColor Cyan
                if ($selectedEncoder -eq "libx264") {
                    $selectedEncoder = $enc.Name
                }
            }
        } catch {
            # Ignore errors
        }
    }

    # Mark selected encoder
    $selectedDesc = ($encoders | Where-Object { $_.Name -eq $selectedEncoder }).Desc
    Write-Host ("  [INFO] [OK] " + $selectedDesc + " - [Selected]") -ForegroundColor Green

    return $selectedEncoder
}

# Process single video
function Process-Video {
    param(
        [string]$InputFile,
        [string]$OutputFile,
        [string]$Encoder
    )

    $filename = Split-Path $InputFile -Leaf
    Write-Host "[INFO] Processing: $filename" -ForegroundColor Green

    # Detect audio track count
    $audioOutput = ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 $InputFile 2>&1
    $audioCount = ($audioOutput | Measure-Object -Line).Lines
    Write-Host "  Detected $audioCount audio track(s)"

    # Get source video bitrate
    $sourceBitrate = ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 $InputFile 2>$null
    if ([string]::IsNullOrEmpty($sourceBitrate) -or $sourceBitrate -eq 0) {
        $targetBitrate = 0
    } else {
        $targetBitrate = [int]$sourceBitrate / 1000
        Write-Host "  Source bitrate reference: ${targetBitrate} kbps"
    }

    # Build ffmpeg parameters
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

    # Execute conversion
    Write-Host "  Starting encoding..." -ForegroundColor Yellow

    # Build ffmpeg arguments
    $ffmpegArgs = @()

    # Input file (use quotes for paths with spaces)
    $ffmpegArgs += "-i"
    $ffmpegArgs += "`"$InputFile`""

    if ($audioCount -gt 1) {
        Write-Host "  Using mix filter to merge $audioCount audio tracks"
        $ffmpegArgs += "-filter_complex"
        $ffmpegArgs += "amix:inputs=$audioCount:duration=longest[a]"
        $ffmpegArgs += "-map"
        $ffmpegArgs += "0:v"
        $ffmpegArgs += "-map"
        $ffmpegArgs += "[a]"
    } else {
        $ffmpegArgs += "-map"
        $ffmpegArgs += "0"
    }

    # Add video parameters (split by space and add each)
    $videoParams.Split(" ") | ForEach-Object {
        if (-not [string]::IsNullOrWhiteSpace($_)) {
            $ffmpegArgs += $_
        }
    }

    # Add audio parameters (split by space and add each)
    $audioParams.Split(" ") | ForEach-Object {
        if (-not [string]::IsNullOrWhiteSpace($_)) {
            $ffmpegArgs += $_
        }
    }

    # Output parameters
    $ffmpegArgs += "-movflags"
    $ffmpegArgs += "+faststart"
    $ffmpegArgs += "-y"
    $ffmpegArgs += "`"$OutputFile`""

    # Run ffmpeg
    $process = Start-Process -FilePath "ffmpeg" -ArgumentList $ffmpegArgs -NoNewWindow -PassThru -Wait

    # Check output file
    if (Test-Path $OutputFile) {
        $fileSize = (Get-Item $OutputFile).Length
        if ($fileSize -gt 0) {
            Write-Host "  Completed: $(Split-Path $OutputFile -Leaf)" -ForegroundColor Green
            return $true
        }
    }

    Write-Host "  [WARNING] Processing failed: $filename (output file not created)" -ForegroundColor Yellow
    return $false
}

# ========== Main Program ==========

# Smart parameter handling
if ([string]::IsNullOrEmpty($InputDir) -and [string]::IsNullOrEmpty($OutputDir)) {
    # Default mode: use script directory
    $InputDir = Split-Path -Parent $PSScriptRoot
    $OutputDir = Join-Path $InputDir "output"

    Write-Host "[INFO] Default mode: Process current directory and subfolders" -ForegroundColor Green
    Write-Host "[INFO] Input directory: $InputDir"
    Write-Host "[INFO] Output directory: $OutputDir"
    Write-Host ""
} elseif ([string]::IsNullOrEmpty($InputDir) -or [string]::IsNullOrEmpty($OutputDir)) {
    Show-Usage
} else {
    Write-Host "[INFO] Custom path mode" -ForegroundColor Green
    Write-Host "[INFO] Input directory: $InputDir"
    Write-Host "[INFO] Output directory: $OutputDir"
    Write-Host ""
}

# Check dependencies
Test-Dependencies

# Detect hardware encoder
$hwEncoder = Get-HardwareEncoder
Write-Host ""

# Validate input directory
if (-not (Test-Path $InputDir)) {
    Write-Host "[ERROR] Input directory does not exist: $InputDir" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
Write-Host "[INFO] Output directory: $OutputDir" -ForegroundColor Green

# Find video files (recursive all subfolders)
Write-Host "[INFO] Scanning video files..." -ForegroundColor Green

$videoFiles = Get-ChildItem -Path $InputDir -Recurse -Include *.mkv, *.mov, *.mp4 -File | Where-Object { $_.DirectoryName -notlike "*\output" }

$totalFiles = $videoFiles.Count

if ($totalFiles -eq 0) {
    Write-Host "[ERROR] No video files found (mkv/mov/mp4)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[INFO] Found $totalFiles video file(s)" -ForegroundColor Green
Write-Host ""

# Process each video file
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

# Summary
Write-Host "===================================" -ForegroundColor Cyan
Write-Host "[INFO] Processing completed!" -ForegroundColor Green
Write-Host "  Success: $successCount"
Write-Host "  Failed: $failCount"
Write-Host "  Total: $totalFiles"
Write-Host "===================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
