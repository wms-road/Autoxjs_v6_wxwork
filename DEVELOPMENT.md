# 开发指南：从 clone 到装真机体验

本仓库是 **AutoX 引擎的自研版（ozobi 分支 v6 flavor）**，编译产物是一个 Android APK（包名 `org.autojs.autoxjs.ozobi.v6`）。
它本身就是运行 JS 脚本的宿主环境；企业微信机器人脚本（在 `wxwork-bot/device/` 仓库）后续通过 AutoX 的"导入脚本/布局分析"加载运行。

本指南只解决一件事：**clone 本仓库 → 编出 APK → 装到安卓真机**，让你能跑起引擎、用布局分析工具现场校准控件。

> 更完整的编译原理 / FAQ（签名、双 NDK、文档占位、Gradle 版本等）见 `wxwork-bot` 仓库的 `实现指南.md` §4、§7。

---

## 1. 环境前置

| 项 | 要求 | 说明 |
| --- | --- | --- |
| 系统 | Windows 10/11 | 构建脚本是 PowerShell（`build-apk.ps1`/`.bat`）。macOS/Linux 请用自带的 `./gradlew`（手动配置 JDK/SDK 后执行 `:app:assembleV6Debug`）。 |
| JDK | 17 | `build-apk.ps1` 默认 `D:\Java\jdk-17.0.8`，**需改成你本机路径**。 |
| Android SDK | cmdline-tools + sdkmanager | `build-apk.ps1` 默认 `D:\Android\Sdk`，**需改成你本机路径**。 |
| SDK 组件 | `build-tools;35.0.0`、`platforms;android-35`、`cmake;3.22.1` | 首次构建时 `:app` 会按需拉取；NDK 由脚本自动装。 |
| 真机 | 安卓 8+，USB 调试已开 | 用于 `adb install` 与后续脚本体验。 |
| 网络 | 首次构建需联网 | 拉 Gradle 8.7、AGP 8.6、依赖、两个 NDK（每个约 1GB）；依赖缓存后二次构建基本离线。 |

> 仓库已做去私有化：`gradle.properties` 原作者代理、`build.gradle.kts` 原作者 nexus 已注释，并加了阿里云 jcenter + 华为云 maven 镜像；`autojs/libs/RootShell-1.6.jar` 本地 vendoring；`app/src/main/assets/docs/index.html` 占位已入库跳过文档联网下载。

---

## 2. Clone

```powershell
git clone https://github.com/wms-road/Autoxjs_v6_wxwork.git
cd Autoxjs_v6_wxwork
```

---

## 3. 修改本机路径（必做）

用编辑器打开 `build-apk.ps1`，改第 33、34 行两处默认值：

```powershell
$JAVA_HOME    = "D:\Java\jdk-17.0.8"   # 改成本机 JDK 17 根目录
$ANDROID_HOME = "D:\Android\Sdk"        # 改成本机 Android SDK 根目录
```

> 若你本机需走代理才能访问外网，取消 `build-apk.ps1` 第 46 行注释并填实际代理地址，否则保持注释以免干扰。

---

## 4. 构建 APK

**推荐**：直接双击 `build-apk.bat`（内部 `chcp 65001` + 调用 `build-apk.ps1`，避免中文乱码）。

或在仓库根目录 PowerShell 里手动运行：

```powershell
.\build-apk.ps1
```

运行后交互询问：

```
请选择构建类型:
  1) Debug   - Android 默认 debug 密钥，可直接 adb install（POC 推荐）
  2) Release - 签名包，用于分发/安装到多台手机
请输入 1 或 2（直接回车默认 1）
```

- **首次建议选 `1`（Debug）**：用 Android 默认 debug 密钥，产物可直接 `adb install`，无需任何签名配置。
- 选 `2`（Release）：脚本会自动调用 `scripts/gen-sign.ps1` 生成 `sign/my-release.jks` + `sign/sign.properties`（自签名，无需应用市场），再 `assembleV6Release`。

构建过程会自动完成：

1. 校验 JDK / SDK / gradlew 是否存在（缺失直接报错退出）。
2. 通过 `sdkmanager` 安装缺失的 NDK：
   - `26.2.11394342`（r26c，`app`/`inrt` 用）
   - `26.1.10909125`（r26b，`ppocrv5` OCR 模块用）
3. `gradlew` 首次运行会自动下载 Gradle 8.7（AGP 8.6.0 要求 ≥8.7）到 `~/.gradle/wrapper/dists/`。
4. `preBuild` 钩子检测到 `app/src/main/assets/docs/index.html` 占位即跳过文档联网下载。
5. 执行 `:app:assembleV6Debug`（或 `:app:assembleV6Release`）。

构建耗时通常 5~15 分钟（取决于机器与依赖缓存）。

---

## 5. 取产物

构建完成脚本会打印产物路径，Debug 包形如：

```
app\build\outputs\apk\v6\debug\app-v6-arm64-v8a-debug.apk     ← 手机(arm64)建议装这个
app\build\outputs\apk\v6\debug\app-v6-universal-debug.apk
```

手机是 arm64 架构，优先装 `app-v6-arm64-v8a-debug.apk`。

---

## 6. 安装到真机

**自动方式（推荐）**：双击 `install-apk.bat`（或 `.\install-apk.ps1`），脚本会自动：
- 定位产物 APK（优先 `app-v6-arm64-v8a-debug.apk`，找不到再退到 universal/其他）；
- 检测已连接且 `device` 状态的设备（多设备时交互让你选序号）；
- 执行 `adb install -r <apk>`。

若 `adb` 不在默认 `D:\Android\Sdk\platform-tools\adb.exe`，请改 `install-apk.ps1` 顶部的 `$ANDROID_HOME`，或把 `platform-tools` 加进 PATH。

**手动方式**：

1. 手机开启 **开发者选项 → USB 调试**，用数据线连电脑；弹窗"允许 USB 调试"点确定。
2. 电脑端确认 `adb devices` 能看到该设备（无 adb 就在 SDK 的 `platform-tools/` 下用，或加进 PATH）。
3. 安装：

```powershell
adb install -r app\build\outputs\apk\v6\debug\app-v6-arm64-v8a-debug.apk
```

4. 首次安装后，到手机 **设置 → 应用 → AutoX(ozobi) → 权限**，授予：
   - 无障碍服务（脚本运行必需）
   - 悬浮窗、通知监听、存储权限
   - 电池优化 → 设为"不限制"（保活，避免被系统杀）
5. 打开 AutoX，能看到脚本管理界面即说明引擎装好。

> 包名：`org.autojs.autoxjs.ozobi.v6`。本引擎只是运行环境；要跑企业微信机器人，把 `wxwork-bot/device/` 的脚本导入 AutoX 即可（详见该仓库说明）。

---

## 7. 常用辅助脚本（仓库 `scripts/`）

| 脚本 | 用途 |
| --- | --- |
| `gen-sign.ps1` | Release 自动生成自签名 `sign/`（jks + properties）。 |
| `addbom.ps1 -Path <file>` | 给 `.ps1` 加 UTF-8 BOM，解决 GBK 控制台读中文源码乱码。 |
| `verifyscript.ps1 -Path <file>` | 用 PowerShell 解析器校验 `.ps1` 语法、不执行，改完自检用。 |

根目录另有两个一键脚本：`build-apk.bat`（构建）、`install-apk.bat`（装真机）。

---

## 8. 排错速查

- **`未找到 JDK` / `未找到 sdkmanager`**：`build-apk.ps1` 第 33/34 行路径没改对，或 SDK 没装 cmdline-tools。
- **NDK 安装卡住/失败**：检查网络或配置代理（见 §3）。两个 NDK 都要成功，缺任一个原生模块编不过。
- **Gradle 下载慢/失败**：依赖阿里云/华为云镜像；如需代理在 `build-apk.ps1` 第 46 行开启。
- **`adb install` 报 `INSTALL_PARSE_FAILED_NO_CERTIFICATES`**：说明装的是未签名 Release 包（签名生成失败）。改用 Debug 包，或确认 `sign/` 已生成后再编 Release。
- **`install-apk.ps1` 报找不到设备**：手机未开 USB 调试 / 未授权；`adb devices` 仅显示 `unauthorized` 时去手机点"允许"。
- **想离线且含真文档**：当前占位方案 APK 帮助页空白（POC 无影响）。要真文档，把 `code-lib/AutoxjsDocs` 构建产物解压进 `app/src/main/assets/docs/`（需生成 `index.html`），且 **不要执行 `gradlew clean`**（会删该目录重新触发下载）。
- **配置期报 `properties.getProperty("storeFile") must not be null`**：说明 `sign/sign.properties` 损坏（常见于旧方式生成时带 UTF-8 BOM，Gradle 按 ISO-8859-1 读把 BOM 拼到首行 key 前）。修复：运行 `scripts/gen-sign.ps1` 重新生成干净文件（已改为无 BOM ASCII 写入）；`app`/`inrt` 的 `build.gradle.kts` 也已加防御性判空——文件缺字段只跳过 Release 签名，Debug 不受影响。
