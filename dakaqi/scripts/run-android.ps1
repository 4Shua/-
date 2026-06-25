# 在手机上运行 — 必须用 ASCII 路径（subst 映射），否则 aapt 会报 Illegal byte sequence
# 用法：PowerShell 中执行 .\scripts\run-android.ps1

$ErrorActionPreference = "Stop"

$projectReal = $PSScriptRoot | Split-Path -Parent
$substDrive = "X:"

# 若已有映射先卸载
subst $substDrive /d 2>$null | Out-Null
subst $substDrive $projectReal

# Gradle 缓存放 D 盘
$gradleHome = "D:\gradle-home"
if (-not (Test-Path $gradleHome)) { New-Item -ItemType Directory -Path $gradleHome | Out-Null }
$env:GRADLE_USER_HOME = $gradleHome

# Flutter / Android
$env:Path = "D:\Flutter\bin;$env:LOCALAPPDATA\Android\Sdk\platform-tools;" + $env:Path
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:ANDROID_SDK_ROOT = "$env:LOCALAPPDATA\Android\Sdk"

Set-Location $substDrive

Write-Host "项目路径（ASCII）: $substDrive -> $projectReal" -ForegroundColor Green
Write-Host "=== adb devices ===" -ForegroundColor Cyan
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices

Write-Host "`n=== flutter run ===" -ForegroundColor Cyan
flutter run

# 运行结束后可选：subst X: /d
