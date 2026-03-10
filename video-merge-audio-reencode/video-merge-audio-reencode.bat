@echo off
REM 视频处理脚本 (Windows 版本)
REM 功能：将指定目录中的视频文件的所有音频轨道混音合并，视频用h.264重新编码
REM 作者：RoL1n
REM 许可证：MIT

setlocal enabledelayedexpansion

REM 检查参数并设置模式
if "%~1"=="" (
    if "%~2"=="" (
        REM 默认模式：使用脚本所在目录
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
        REM 自定义路径模式
        set "INPUT_DIR=%~1"
        set "OUTPUT_DIR=%~2"
        set "MODE=CUSTOM"
    )
)

REM 显示模式信息
if "%MODE%"=="DEFAULT" (
    echo [信息] 默认模式：处理当前目录及子文件夹
    echo [信息] 输入目录: %INPUT_DIR%
    echo [信息] 输出目录: %OUTPUT_DIR%
    echo.
) else (
    echo [信息] 自定义路径模式
    echo [信息] 输入目录: %INPUT_DIR%
    echo [信息] 输出目录: %OUTPUT_DIR%
    echo.
)

REM 检查依赖
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo [错误] 未找到 ffmpeg
    echo 请先安装 ffmpeg 并添加到 PATH 环境变量
    echo 下载地址: https://www.gyan.dev/ffmpeg/builds/
    exit /b 1
)

echo [信息] 依赖检查通过

REM 验证输入目录
if not exist "%INPUT_DIR%" (
    echo [错误] 输入目录不存在: %INPUT_DIR%
    exit /b 1
)

REM 创建输出目录
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
echo [信息] 输出目录: %OUTPUT_DIR%

REM 查找视频文件（递归所有子文件夹）
echo [信息] 扫描视频文件...

set COUNT=0
for /r "%INPUT_DIR%" %%F in (*.mkv *.mov *.mp4) do (
    set /a COUNT+=1
)

if %COUNT%==0 (
    echo [错误] 未找到任何视频文件 (mkv/mov/mp4)
    exit /b 1
)

echo [信息] 找到 %COUNT% 个视频文件
echo.

REM 处理每个视频文件
set SUCCESS=0
set FAIL=0

for /r "%INPUT_DIR%" %%F in (*.mkv *.mov *.mp4) do (
    set "INPUT_FILE=%%F"
    set "FILENAME=%%~nxF"

    echo [信息] 正在处理: !FILENAME!

    REM 获取输出文件名（统一为 .mp4）
    set "OUTPUT_FILE=%OUTPUT_DIR%\%%~nF.mp4"

    REM 检测音频轨道数量
    for /f "tokens=*" %%A in ('ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "!INPUT_FILE!" 2^>nul ^| find /c /v ""') do set AUDIO_COUNT=%%A

    echo   检测到 !AUDIO_COUNT! 个音频轨道

    REM 获取源视频比特率
    for /f "tokens=*" %%B in ('ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "!INPUT_FILE!" 2^>nul') do set SOURCE_BITRATE=%%B

    if "!SOURCE_BITRATE!"=="" set SOURCE_BITRATE=0

    REM 编码参数设置
    set "VIDEO_PARAMS=-c:v libx264 -preset medium -crf 23"
    set "AUDIO_PARAMS=-c:a aac -b:a 192k -ac 2"

    if !SOURCE_BITRATE! GTR 0 (
        set /a TARGET_BITRATE=!SOURCE_BITRATE!/1000
        echo   源视频参考比特率: !TARGET_BITRATE! kbps

        if !TARGET_BITRATE! LSS 2000 (
            set "VIDEO_PARAMS=-c:v libx264 -preset medium -crf 20"
        ) else (
            set /a BUF_SIZE=!TARGET_BITRATE!*2
            set "VIDEO_PARAMS=-c:v libx264 -preset medium -b:v !TARGET_BITRATE!k -maxrate !TARGET_BITRATE!k -bufsize !BUF_SIZE!k"
        )
    )

    REM 执行转换
    echo   开始编码...

    if !AUDIO_COUNT! GTR 1 (
        REM 多音轨混音
        ffmpeg -i "!INPUT_FILE!" -filter_complex "amix=inputs=!AUDIO_COUNT!:duration=longest" -map 0:v -map "[a]" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!" >nul 2>&1
    ) else (
        REM 单音轨
        ffmpeg -i "!INPUT_FILE!" !VIDEO_PARAMS! !AUDIO_PARAMS! -movflags +faststart -y "!OUTPUT_FILE!" >nul 2>&1
    )

    if errorlevel 1 (
        echo   [警告] 处理失败: !FILENAME!
        set /a FAIL+=1
    ) else (
        echo   完成: %%~nF.mp4
        set /a SUCCESS+=1
    )

    echo.
)

REM 总结
echo ===================================
echo [信息] 处理完成！
echo   成功: %SUCCESS%
echo   失败: %FAIL%
echo   总计: %COUNT%
echo ===================================

endlocal
exit /b 0

:usage
echo 用法: %~nx0 [输入目录] [输出目录]
echo.
echo 功能：
echo   - 扫描输入目录中的 mkv/mov/mp4 视频文件（递归所有子文件夹）
echo   - 将每个视频的所有音频轨道混音合并为一个音轨
echo   - 使用 h.264 重新编码视频（参考源视频质量）
echo   - 保持原视频的分辨率和帧率
echo   - 输出为 MP4 格式到指定目录
echo.
echo 使用方式：
echo   1. 默认模式（推荐）
echo      将脚本放入视频文件夹中，直接运行：
echo      %~nx0
echo      自动处理当前目录及所有子文件夹，输出到 'output' 文件夹
echo.
echo   2. 自定义路径模式
echo      指定输入和输出目录：
echo      %~nx0 C:\Videos\raw C:\Videos\processed
echo.
echo 依赖：
echo   - ffmpeg (需要添加到 PATH 环境变量)
echo.
echo 示例：
echo   # 默认模式：处理当前目录及子文件夹
echo   %~nx0
echo.
echo   # 自定义路径
echo   %~nx0 C:\Videos\raw_movies C:\Videos\processed
exit /b 1
