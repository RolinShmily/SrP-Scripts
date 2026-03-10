@echo off
REM Video Processing Script (Windows)
REM Merge audio tracks and re-encode video to H.264
REM Author: RoL1n
REM License: MIT

setlocal enabledelayedexpansion

cd /d "%~dp0"

echo Starting video processing script...
echo Working directory: %CD%
echo.

REM Check dependencies
echo Checking ffmpeg...

REM Try to find ffmpeg in system PATH
set "FFMPEG_PATH="
where ffmpeg >nul 2>&1
if not errorlevel 1 (
    set "FFMPEG_PATH=ffmpeg"
    goto :ffmpeg_found
)

REM Check local cache directory
set "CACHE_DIR=%USERPROFILE%\.srp-scripts\ffmpeg"
set "LOCAL_FFMPEG=%CACHE_DIR%\ffmpeg.exe"

if exist "%LOCAL_FFMPEG%" (
    set "FFMPEG_PATH=%LOCAL_FFMPEG%"
    goto :ffmpeg_found
)

REM Download ffmpeg automatically
echo ffmpeg not found in system PATH or local cache
echo.
echo [INFO] Downloading ffmpeg automatically...
echo This will only happen once. Future runs will use the cached version.
echo.

REM Create cache directory
if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"

REM Download ffmpeg using PowerShell
set "DOWNLOAD_URL=https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
set "ZIP_FILE=%CACHE_DIR%\ffmpeg.zip"

echo Downloading from: %DOWNLOAD_URL%
echo.

powershell -Command "& {Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing}"
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to download ffmpeg
    echo Please check your internet connection or download manually:
    echo %DOWNLOAD_URL%
    echo.
    pause
    exit /b 1
)

echo Download completed. Extracting...
echo.

REM Extract only ffmpeg.exe using PowerShell
powershell -Command "& {Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%ZIP_FILE%', '%CACHE_DIR%'); $folder = Get-ChildItem '%CACHE_DIR%' -Directory | Select-Object -First 1; Move-Item -Path \"$($folder.FullName)\*\" -Destination '%CACHE_DIR%' -Force; Remove-Item -Path \"$($folder.FullName)\" -Force; Remove-Item '%ZIP_FILE%' -Force}"

if not exist "%LOCAL_FFMPEG%" (
    echo.
    echo [ERROR] Failed to extract ffmpeg
    echo.
    pause
    exit /b 1
)

echo ffmpeg installed successfully to: %CACHE_DIR%
echo.
echo [INFO] You can delete this cache anytime to reclaim space:
echo   %CACHE_DIR%
echo.

:ffmpeg_found
echo [OK] ffmpeg found

REM Set ffprobe path based on ffmpeg location
set "FFPROBE_PATH="
if "%FFMPEG_PATH%"=="ffmpeg" (
    set "FFPROBE_PATH=ffprobe"
) else (
    set "FFPROBE_PATH=%FFMPEG_PATH:\ffmpeg.exe=\ffprobe.exe%"
)
echo.

REM Create output directory
if not exist "output" mkdir "output"

REM Find video files
echo Scanning for video files...

set COUNT=0
for %%F in (*.mkv *.mov *.mp4) do set /a COUNT+=1

for /d %%D in (*) do (
    if /i not "%%D"=="output" (
        for %%F in ("%%D\*.mkv" "%%D\*.mov" "%%D\*.mp4") do (
            if exist "%%F" set /a COUNT+=1
        )
    )
)

echo Found %COUNT% video file(s)
echo.

if %COUNT%==0 (
    echo [ERROR] No video files found
    pause
    exit /b 1
)

REM Detect encoder
set "HW_ENCODER=libx264"
echo Detecting encoder...

"%FFMPEG_PATH%" -hide_banner -encoders 2>nul | findstr /C:"h264_nvenc" >nul
if !errorlevel! equ 0 (
    set "HW_ENCODER=h264_nvenc"
    echo   Using: NVIDIA NVENC
)

if "!HW_ENCODER!"=="libx264" (
    "%FFMPEG_PATH%" -hide_banner -encoders 2>nul | findstr /C:"h264_amf" >nul
    if !errorlevel! equ 0 (
        set "HW_ENCODER=h264_amf"
        echo   Using: AMD AMF
    )
)

if "!HW_ENCODER!"=="libx264" (
    "%FFMPEG_PATH%" -hide_banner -encoders 2>nul | findstr /C:"h264_qsv" >nul
    if !errorlevel! equ 0 (
        set "HW_ENCODER=h264_qsv"
        echo   Using: Intel Quick Sync
    )
)

if "!HW_ENCODER!"=="libx264" echo   Using: CPU (libx264)
echo.

REM Process videos in current directory
set SUCCESS=0
set FAIL=0

for %%F in (*.mkv *.mov *.mp4) do (
    set "INPUT_FILE=%%F"
    set "FILENAME=%%~nxF"
    set "OUTPUT_FILE=output\%%~nF.mp4"

    echo [INFO] Processing: !FILENAME!

    REM Get audio count
    "%FFPROBE_PATH%" -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "!INPUT_FILE!" 2>nul > "%TEMP%\audio_tmp.txt"
    for /f %%A in ('type "%TEMP%\audio_tmp.txt" ^| find /c /v ""') do set AUDIO_COUNT=%%A
    del "%TEMP%\audio_tmp.txt" 2>nul
    echo   Audio tracks: !AUDIO_COUNT!

    REM Get bitrate
    "%FFPROBE_PATH%" -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "!INPUT_FILE!" 2>nul > "%TEMP%\bitrate_tmp.txt"
    set /p SOURCE_BITRATE=<"%TEMP%\bitrate_tmp.txt"
    del "%TEMP%\bitrate_tmp.txt" 2>nul
    if "!SOURCE_BITRATE!"=="" set SOURCE_BITRATE=0

    REM Calculate target bitrate
    set TARGET_BITRATE=0
    if !SOURCE_BITRATE! GTR 0 (
        set /a TARGET_BITRATE=!SOURCE_BITRATE!/1000
        echo   Source bitrate: !TARGET_BITRATE! kbps
    )

    REM Build encoding parameters
    set CRF_VALUE=23
    if !TARGET_BITRATE! GTR 0 (
        if !TARGET_BITRATE! LSS 2000 set CRF_VALUE=20
    )

    REM Set video params based on encoder
    if "!HW_ENCODER!"=="h264_nvenc" (
        REM Use simple NVENC params for compatibility with older ffmpeg
        if !TARGET_BITRATE! GTR 0 (
            set "VIDEO_PARAMS=-c:v h264_nvenc -preset fast -cq !CRF_VALUE! -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k"
        ) else (
            set "VIDEO_PARAMS=-c:v h264_nvenc -preset fast -cq !CRF_VALUE!"
        )
    ) else if "!HW_ENCODER!"=="h264_amf" (
        if !TARGET_BITRATE! GTR 0 (
            set /a BUF_SIZE=!TARGET_BITRATE!*2
            set "VIDEO_PARAMS=-c:v h264_amf -quality speed -rc vbr -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k -bufsize !BUF_SIZE!k"
        ) else (
            set "VIDEO_PARAMS=-c:v h264_amf -quality speed -rc vbr"
        )
    ) else if "!HW_ENCODER!"=="h264_qsv" (
        if !TARGET_BITRATE! GTR 0 (
            set /a BUF_SIZE=!TARGET_BITRATE!*2
            set "VIDEO_PARAMS=-c:v h264_qsv -preset medium -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k -bufsize !BUF_SIZE!k -global_quality !CRF_VALUE!"
        ) else (
            set "VIDEO_PARAMS=-c:v h264_qsv -preset medium -global_quality !CRF_VALUE!"
        )
    ) else (
        if !TARGET_BITRATE! GEQ 2000 (
            set /a BUF_SIZE=!TARGET_BITRATE!*2
            set "VIDEO_PARAMS=-c:v libx264 -preset medium -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k -bufsize !BUF_SIZE!k"
        ) else (
            set "VIDEO_PARAMS=-c:v libx264 -preset medium -crf !CRF_VALUE!"
        )
    )

    set "AUDIO_PARAMS=-c:a aac -b:a 192k -ac 2"

    echo   Encoding...

    REM Execute ffmpeg with output visible for debugging
    if !AUDIO_COUNT! GTR 1 (
        "%FFMPEG_PATH%" -i "!INPUT_FILE!" -filter_complex "amix=inputs=!AUDIO_COUNT!:duration=longest[a]" -map 0:v -map "[a]" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
    ) else (
        "%FFMPEG_PATH%" -i "!INPUT_FILE!" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
    )

    REM Check output
    if exist "!OUTPUT_FILE!" (
        for %%S in ("!OUTPUT_FILE!") do set FILE_SIZE=%%~zS
        if !FILE_SIZE! GTR 0 (
            echo   Done
            set /a SUCCESS+=1
        ) else (
            echo   Failed: Output file is empty
            set /a FAIL+=1
        )
    ) else (
        echo   Failed: Output file not created
        set /a FAIL+=1
    )
    echo.
)

REM Process subdirectories (excluding output)
for /d %%D in (*) do (
    if /i not "%%D"=="output" (
        pushd "%%D"
        for %%F in (*.mkv *.mov *.mp4) do (
            set "INPUT_FILE=%%F"
            set "FILENAME=%%~nxF"
            set "OUTPUT_FILE=..\output\%%~nF.mp4"

            echo [INFO] Processing: %%D\!FILENAME!

            REM Get audio count
            "%FFPROBE_PATH%" -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "!INPUT_FILE!" 2>nul > "%TEMP%\audio_tmp.txt"
            for /f %%A in ('type "%TEMP%\audio_tmp.txt" ^| find /c /v ""') do set AUDIO_COUNT=%%A
            del "%TEMP%\audio_tmp.txt" 2>nul
            echo   Audio tracks: !AUDIO_COUNT!

            REM Get bitrate
            "%FFPROBE_PATH%" -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "!INPUT_FILE!" 2>nul > "%TEMP%\bitrate_tmp.txt"
            set /p SOURCE_BITRATE=<"%TEMP%\bitrate_tmp.txt"
            del "%TEMP%\bitrate_tmp.txt" 2>nul
            if "!SOURCE_BITRATE!"=="" set SOURCE_BITRATE=0

            REM Calculate target bitrate
            set TARGET_BITRATE=0
            if !SOURCE_BITRATE! GTR 0 (
                set /a TARGET_BITRATE=!SOURCE_BITRATE!/1000
                echo   Source bitrate: !TARGET_BITRATE! kbps
            )

            REM Build encoding parameters
            set CRF_VALUE=23
            if !TARGET_BITRATE! GTR 0 (
                if !TARGET_BITRATE! LSS 2000 set CRF_VALUE=20
            )

            REM Set video params based on encoder
            if "!HW_ENCODER!"=="h264_nvenc" (
                if !TARGET_BITRATE! GTR 0 (
                    set /a BUF_SIZE=!TARGET_BITRATE!*2
                    set "VIDEO_PARAMS=-c:v h264_nvenc -preset p4 -rc vbr -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k -bufsize !BUF_SIZE!k -cq !CRF_VALUE!"
                ) else (
                    set "VIDEO_PARAMS=-c:v h264_nvenc -preset p4 -rc vbr -cq !CRF_VALUE!"
                )
            ) else if "!HW_ENCODER!"=="h264_amf" (
                if !TARGET_BITRATE! GTR 0 (
                    set /a BUF_SIZE=!TARGET_BITRATE!*2
                    set "VIDEO_PARAMS=-c:v h264_amf -quality speed -rc vbr -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k -bufsize !BUF_SIZE!k"
                ) else (
                    set "VIDEO_PARAMS=-c:v h264_amf -quality speed -rc vbr"
                )
            ) else if "!HW_ENCODER!"=="h264_qsv" (
                if !TARGET_BITRATE! GTR 0 (
                    set /a BUF_SIZE=!TARGET_BITRATE!*2
                    set "VIDEO_PARAMS=-c:v h264_qsv -preset medium -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k -bufsize !BUF_SIZE!k -global_quality !CRF_VALUE!"
                ) else (
                    set "VIDEO_PARAMS=-c:v h264_qsv -preset medium -global_quality !CRF_VALUE!"
                )
            ) else (
                if !TARGET_BITRATE! GEQ 2000 (
                    set /a BUF_SIZE=!TARGET_BITRATE!*2
                    set "VIDEO_PARAMS=-c:v libx264 -preset medium -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k -bufsize !BUF_SIZE!k"
                ) else (
                    set "VIDEO_PARAMS=-c:v libx264 -preset medium -crf !CRF_VALUE!"
                )
            )

            set "AUDIO_PARAMS=-c:a aac -b:a 192k -ac 2"

            echo   Encoding...

            REM Execute ffmpeg
            if !AUDIO_COUNT! GTR 1 (
                "%FFMPEG_PATH%" -i "!INPUT_FILE!" -filter_complex "amix=inputs=!AUDIO_COUNT!:duration=longest[a]" -map 0:v -map "[a]" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
            ) else (
                "%FFMPEG_PATH%" -i "!INPUT_FILE!" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
            )

            REM Check output
            if exist "!OUTPUT_FILE!" (
                for %%S in ("!OUTPUT_FILE!") do set FILE_SIZE=%%~zS
                if !FILE_SIZE! GTR 0 (
                    echo   Done
                    set /a SUCCESS+=1
                ) else (
                    echo   Failed: Output file is empty
                    set /a FAIL+=1
                )
            ) else (
                echo   Failed: Output file not created
                set /a FAIL+=1
            )
            echo.
        )
        popd
    )
)

echo ===================================
echo Processing completed!
echo   Success: %SUCCESS%
echo   Failed: %FAIL%
echo   Total: %COUNT%
echo ===================================
echo.
endlocal
pause
