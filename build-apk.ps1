# build-apk.ps1 - 将 Autoxjs_v6_wxwork 自研版编译为 debug APK（v6 flavor）
#
# 用法（PowerShell）:
#   cd 到本目录后执行   .\build-apk.ps1
#
# 前置条件（本机已具备，脚本仅做校验）:
#   - JDK 17（编译脚本默认 D:\Java\jdk-17.0.8）
#   - Android SDK（build-tools 35.0.0、platforms android-35、cmake 3.22.1）
#   - 首次运行会自动用 sdkmanager 安装 NDK 26.2.11394342（app 用）与 26.1.10909125（ppocrv5 用）
#
# 本脚本依赖的仓库内已落地改动（无需手动再做）:
#   1) gradle.properties: 原作者私人代理 ozobi-win-asus:7890 已注释
#   2) build.gradle.kts: 原作者私人 nexus(120.25.164.233:8081) 已注释，并新增
#      aliyun jcenter 镜像 + 华为云 maven 镜像（RootShell:1.6 等老库来源）
#   3) autojs/libs/RootShell-1.6.jar: RootShell 1.6 在公共源已绝迹（JitPack 老构建脚本用
#      HTTP 拉 AGP 被 Maven Central 拒、jcenter 镜像已清），改为本地 vendoring 的 jar
#      （由 Stericson/RootShell tag 1.6 源码 javac 编译而来），autojs/build.gradle.kts 改引用本地文件
#   4) app/src/main/assets/docs/index.html 占位: 跳过 installationDocumentation 联网下载文档
#      （APK 不含离线文档；如需文档可删此占位让其联网下载）
#
# 包名: org.autojs.autoxjs.ozobi.v6  （要改成 wxwork 品牌请改 app/build.gradle.kts 的
#        applicationIdSuffix / versionNameSuffix / manifestPlaceholders appName）

$ErrorActionPreference = 'Stop'

# ===================== 1. 路径配置（按本机实际修改） =====================
$JAVA_HOME        = "D:\Java\jdk-17.0.8"
$ANDROID_HOME     = "D:\Android\Sdk"
$PROJECT_DIR      = $PSScriptRoot                                  # 脚本所在目录即工程根
$SDKMANAGER       = Join-Path $ANDROID_HOME "cmdline-tools\latest\bin\sdkmanager.bat"
$GRADLEW          = Join-Path $PROJECT_DIR "gradlew.bat"
# app 用 26.2.11394342；ppocrv5 用 26.1.10909125
$NDK_VERSIONS     = @("26.2.11394342", "26.1.10909125")

# ===================== 2. 设置环境变量 =====================
$env:JAVA_HOME         = $JAVA_HOME
$env:ANDROID_HOME      = $ANDROID_HOME
$env:ANDROID_SDK_ROOT  = $ANDROID_HOME
# 如本机需走代理才能访问外网，请取消下一行注释并填实际代理；否则保持注释以免干扰
# $env:HTTP_PROXY  = "http://127.0.0.1:7890"; $env:HTTPS_PROXY = "http://127.0.0.1:7890"

# ===================== 3. 校验 JDK / SDK =====================
if (-not (Test-Path (Join-Path $JAVA_HOME "bin\javac.exe"))) { Write-Error "未找到 JDK，请检查 JAVA_HOME: $JAVA_HOME"; exit 1 }
if (-not (Test-Path $SDKMANAGER)) { Write-Error "未找到 sdkmanager: $SDKMANAGER"; exit 1 }
if (-not (Test-Path $GRADLEW))   { Write-Error "未找到 gradlew.bat: $GRADLEW"; exit 1 }

# ===================== 4. 安装缺失的 NDK =====================
$ndkBase = Join-Path $ANDROID_HOME "ndk"
foreach ($v in $NDK_VERSIONS) {
    $dest = Join-Path $ndkBase $v
    if (Test-Path $dest) {
        Write-Host "[*] NDK $v 已存在，跳过" -ForegroundColor Green
    } else {
        Write-Host "[*] 未检测到 NDK $v，开始通过 sdkmanager 安装（约 1GB，请耐心等待）..." -ForegroundColor Yellow
        ("y`n" * 40) | & $SDKMANAGER "ndk;$v" 2>&1 | ForEach-Object { Write-Host $_ }
        if (-not (Test-Path $dest)) { Write-Error "NDK $v 安装失败，请检查网络/代理"; exit 1 }
        Write-Host "[*] NDK $v 安装完成" -ForegroundColor Green
    }
}

# ===================== 5. 执行构建 =====================
Write-Host "[*] 开始构建 :app:assembleV6Debug ..." -ForegroundColor Cyan
Push-Location $PROJECT_DIR
try {
    & $GRADLEW ":app:assembleV6Debug" --stacktrace
    if ($LASTEXITCODE -ne 0) { Write-Error "构建失败，详见上方 Gradle 日志"; exit $LASTEXITCODE }
} finally {
    Pop-Location
}

# ===================== 6. 打印产物 =====================
$outDir = Join-Path $PROJECT_DIR "app\build\outputs\apk\v6\debug"
Write-Host "`n[OK] 构建完成，APK 产物:" -ForegroundColor Green
Get-ChildItem $outDir -Filter *.apk | ForEach-Object {
    Write-Host ("  " + $_.FullName + "  (" + [math]::Round($_.Length / 1MB, 1) + " MB)") -ForegroundColor White
}
Write-Host "`n手机(arm64)建议安装: app-v6-arm64-v8a-debug.apk" -ForegroundColor Cyan
Write-Host ("应用包名: org.autojs.autoxjs.ozobi.v6") -ForegroundColor DarkGray
