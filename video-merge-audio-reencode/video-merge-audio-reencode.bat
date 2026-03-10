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
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] ffmpeg not found
    echo Please install ffmpeg and add to PATH
    echo Download: https://www.gyan.dev/ffmpeg/builds/
    echo.
    pause
    exit /b 1
)
echo [OK] ffmpeg found
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

ffmpeg -hide_banner -encoders 2>nul | findstr /C:"h264_nvenc" >nul
if !errorlevel! equ 0 (
    set "HW_ENCODER=h264_nvenc"
    echo   Using: NVIDIA NVENC
)

if "!HW_ENCODER!"=="libx264" (
    ffmpeg -hide_banner -encoders 2>nul | findstr /C:"h264_amf" >nul
    if !errorlevel! equ 0 (
        set "HW_ENCODER=h264_amf"
        echo   Using: AMD AMF
    )
)

if "!HW_ENCODER!"=="libx264" (
    ffmpeg -hide_banner -encoders 2>nul | findstr /C:"h264_qsv" >nul
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
    ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "!INPUT_FILE!" 2>nul > "%TEMP%\audio_tmp.txt"
    for /f %%A in ('type "%TEMP%\audio_tmp.txt" ^| find /c /v ""') do set AUDIO_COUNT=%%A
    del "%TEMP%\audio_tmp.txt" 2>nul
    echo   Audio tracks: !AUDIO_COUNT!

    REM Get bitrate
    ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "!INPUT_FILE!" 2>nul > "%TEMP%\bitrate_tmp.txt"
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
        ffmpeg -i "!INPUT_FILE!" -filter_complex "amix=inputs=!AUDIO_COUNT!:duration=longest[a]" -map 0:v -map "[a]" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
    ) else (
        ffmpeg -i "!INPUT_FILE!" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
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
            ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "!INPUT_FILE!" 2>nul > "%TEMP%\audio_tmp.txt"
            for /f %%A in ('type "%TEMP%\audio_tmp.txt" ^| find /c /v ""') do set AUDIO_COUNT=%%A
            del "%TEMP%\audio_tmp.txt" 2>nul
            echo   Audio tracks: !AUDIO_COUNT!

            REM Get bitrate
            ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "!INPUT_FILE!" 2>nul > "%TEMP%\bitrate_tmp.txt"
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
                ffmpeg -i "!INPUT_FILE!" -filter_complex "amix=inputs=!AUDIO_COUNT!:duration=longest[a]" -map 0:v -map "[a]" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
            ) else (
                ffmpeg -i "!INPUT_FILE!" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!"
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
