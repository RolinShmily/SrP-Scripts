@echo off
REM Video Processing Script (Windows)
REM Merge all audio tracks and re-encode video to H.264
REM Author: RoL1n
REM License: MIT

setlocal enabledelayedexpansion

REM Check parameters and set mode
if "%~1"=="" (
    if "%~2"=="" (
        REM Default mode: use script directory
        set "INPUT_DIR=%~dp0"
        set "OUTPUT_DIR=%~dp0output"
        set "MODE=DEFAULT"
    ) else (
        goto :usage
    )
) else (
    if "%~2"=="" (
        goto :usage
    ) else (
        REM Custom path mode
        set "INPUT_DIR=%~1"
        set "OUTPUT_DIR=%~2"
        set "MODE=CUSTOM"
    )
)

REM Display mode info
if "%MODE%"=="DEFAULT" (
    echo [INFO] Default mode: Process current directory and subfolders
    echo [INFO] Input directory: %INPUT_DIR%
    echo [INFO] Output directory: %OUTPUT_DIR%
    echo.
) else (
    echo [INFO] Custom path mode
    echo [INFO] Input directory: %INPUT_DIR%
    echo [INFO] Output directory: %OUTPUT_DIR%
    echo.
)

REM Check dependencies
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo [ERROR] ffmpeg not found
    echo Please install ffmpeg and add to PATH environment variable
    echo Download: https://www.gyan.dev/ffmpeg/builds/
    pause
    exit /b 1
)

echo [INFO] Dependencies check passed

REM Validate input directory
if not exist "%INPUT_DIR%" (
    echo [ERROR] Input directory does not exist: %INPUT_DIR%
    pause
    exit /b 1
)

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
echo [INFO] Output directory: %OUTPUT_DIR%

REM Find video files (recursive all subfolders)
echo [INFO] Scanning video files...

set COUNT=0
for /r "%INPUT_DIR%" %%F in (*.mkv *.mov *.mp4) do (
    set /a COUNT+=1
)

if %COUNT%==0 (
    echo [ERROR] No video files found (mkv/mov/mp4)
    pause
    exit /b 1
)

echo [INFO] Found %COUNT% video file(s)
echo.

REM Process each video file
set SUCCESS=0
set FAIL=0

for /r "%INPUT_DIR%" %%F in (*.mkv *.mov *.mp4) do (
    set "INPUT_FILE=%%F"
    set "FILENAME=%%~nxF"

    echo [INFO] Processing: !FILENAME!

    REM Get output filename (uniform as .mp4)
    set "OUTPUT_FILE=%OUTPUT_DIR%\%%~nF.mp4"

    REM Detect audio track count
    for /f "tokens=*" %%A in ('ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "!INPUT_FILE!" 2^>nul ^| find /c /v ""') do set AUDIO_COUNT=%%A

    echo   Detected !AUDIO_COUNT! audio track(s)

    REM Get source video bitrate
    for /f "tokens=*" %%B in ('ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "!INPUT_FILE!" 2^>nul') do set SOURCE_BITRATE=%%B

    if "!SOURCE_BITRATE!"=="" set SOURCE_BITRATE=0

    REM Encoding parameters
    set "VIDEO_PARAMS=-c:v libx264 -preset medium -crf 23"
    set "AUDIO_PARAMS=-c:a aac -b:a 192k -ac 2"

    if !SOURCE_BITRATE! GTR 0 (
        set /a TARGET_BITRATE=!SOURCE_BITRATE!/1000
        echo   Source bitrate reference: !TARGET_BITRATE! kbps

        if !TARGET_BITRATE! LSS 2000 (
            set "VIDEO_PARAMS=-c:v libx264 -preset medium -crf 20"
        ) else (
            set /a BUF_SIZE=!TARGET_BITRATE!*2
            set "VIDEO_PARAMS=-c:v libx264 -preset medium -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k -bufsize !BUF_SIZE!k"
        )
    )

    REM Execute conversion
    echo   Starting encoding...

    if !AUDIO_COUNT! GTR 1 (
        REM Multiple audio tracks - mix
        ffmpeg -i "!INPUT_FILE!" -filter_complex "amix=inputs=!AUDIO_COUNT!:duration=longest[a]" -map 0:v -map "[a]" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
    ) else (
        REM Single audio track
        ffmpeg -i "!INPUT_FILE!" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
    )

    REM Check if output file was actually created
    if exist "!OUTPUT_FILE!" (
        echo   Completed: %%~nF.mp4
        set /a SUCCESS+=1
    ) else (
        echo   [WARNING] Processing failed: !FILENAME! (output file not created)
        set /a FAIL+=1
    )

    echo.
)

REM Summary
echo ===================================
echo [INFO] Processing completed!
echo   Success: %SUCCESS%
echo   Failed: %FAIL%
echo   Total: %COUNT%
echo ===================================
pause

endlocal
exit /b 0

:usage
echo Usage: %~nx0 [input_directory] [output_directory]
echo.
echo Features:
echo   - Scan mkv/mov/mp4 video files in input directory (recursive all subfolders)
echo   - Mix all audio tracks into one
echo   - Re-encode video to H.264 (smart quality reference)
echo   - Keep original resolution and frame rate
echo   - Output as MP4 format
echo.
echo Usage modes:
echo   1. Default mode (recommended)
echo      Place script in video folder and run:
echo      %~nx0
echo      Auto process current directory and subfolders, output to 'output' folder
echo.
echo   2. Custom path mode
echo      Specify input and output directories:
echo      %~nx0 C:\Videos\raw C:\Videos\processed
echo.
echo Dependencies:
echo   - ffmpeg (must be added to PATH environment variable)
echo.
echo Examples:
echo   # Default mode: process current directory and subfolders
echo   %~nx0
echo.
echo   # Custom path
echo   %~nx0 C:\Videos\raw_movies C:\Videos\processed
pause
exit /b 1
