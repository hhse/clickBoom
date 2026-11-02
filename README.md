# clickBoom

一个轻量、原生的 macOS 全局鼠标点击特效工具。它会监听鼠标点击，并在点击位置绘制即时动画，让演示、录屏、直播和日常操作更有反馈感。

项目使用 SwiftUI 和 macOS 原生 API 编写，不依赖第三方运行库。

## ✨ 功能特性

- 全局监听鼠标左键、右键与中键点击（右键/中键可单独关闭）
- 11 种可切换的点击效果：
  - 火花：短线条向外散开
  - 圆环：一段圆弧从点击位置展开
  - 光线：几条细光线快速划过
  - 彩纸：小块彩纸轻轻飘开
  - 表情：点击弹出自定义 Emoji，带轻微弹性、漂浮和旋转动画
  - 水波：三圈涟漪依次向外扩散、逐圈变淡
  - 星芒：四长四短的尖细星芒 + 中心高光，像镜头光晕
  - 像素：8-bit 小方块四散旋转、边飞边缩小
  - 爱心：小爱心错峰上浮，带轻微摇摆与旋转
  - 烟花：焰火炸开后拖尾下坠，中心带一圈闪光
  - 闪电：锯齿电弧向外劈开，外层发光、内层亮芯
- 支持自定义效果颜色，并提供 6 个常用色块一键切换
- 支持输入一个或多个自定义 Emoji，多个 Emoji 会在每次点击时随机选择；也可点选常用 Emoji 快速加入
- 内置 6 组快捷预设：默认、蓝光、圆环、彩纸、赛博、烟花
- 支持把自己的整套参数保存成自定义预设（同名覆盖），随时一键套用或删除
- 支持暂停 15 / 30 / 60 分钟：演示中途临时关掉效果，到点自动恢复
- 支持全局快捷键 ⌃⌥B：在任意 App 里快速开关特效
- 支持调整粒子数量、大小、扩散半径、动画时长和缩放比例
- Emoji 模式支持在控制面板或菜单栏直接编辑自定义表情
- 菜单栏提供快速面板，可直接开关、预览、定时暂停、套用预设，并快速调整常用参数；图标会随开关变暗，暂停时显示暂停标记
- 面板内可一键「预览」当前效果，调完参数立刻看到结果，也能一键「恢复默认设置」
- 跟随系统「减弱动态效果」：开启后自动收起旋转与摇摆
- 随机样式：每次点击自动抽取一种样式
- 连续点击放大：短时间连续点击会逐步增加粒子数量和范围
- 支持开机自启（基于系统登录项，可随时在控制面板或菜单栏开关）
- 自动检测「输入监控」权限，未授权时直接在面板里提示并一键跳转设置，授权后立即生效、无需重启
- 支持多显示器：覆盖层铺满所有屏幕，副屏/竖屏点击同样有效，插拔显示器自动适配
- 启动时只留在菜单栏，不弹面板（开机自启也不会打断登录），点 Dock 图标可随时叫回
- 空闲时暂停动画渲染，不点击就不占绘图资源
- 控制面板可拖拽调整窗口大小
- 内置「检查更新」，直接对比 GitHub 上最新 Release；启动后每天自动检查一次，有新版本时菜单栏图标显示小圆点
- 设置会自动保存，下次启动时继续使用
- 使用透明悬浮层绘制，不影响鼠标正常操作
- 原生 SwiftUI 界面，轻量且易于扩展

## 🖥️ 系统要求

- macOS 26.0 或更高版本
- Xcode 26.0 或更高版本（仅编译时需要）

首次运行时，系统会请求「输入监控」权限，用于接收其他应用中的全局鼠标点击事件。路径：系统设置 → 隐私与安全性 → 输入监控 → 勾选 ClickBoom。授权后无需重启 App，点击效果会立即生效。

## 📦 安装

1. 到 [Releases](https://github.com/hhse/clickBoom/releases) 下载最新的 `ClickBoom-x.y.z.dmg`。
2. 打开 DMG，把 ClickBoom 拖进「应用程序」。
3. 首次打开时，如果看到「无法验证开发者」的提示，说明安装包还没有经过 Apple 公证。任选一种方式放行：
   - 在「应用程序」里 **右键点击 ClickBoom → 打开 → 再点「打开」**；
   - 打开 系统设置 → 隐私与安全性，在底部点「仍要打开」；
   - 或者用命令行去掉隔离标记：
     ```bash
     xattr -dr com.apple.quarantine /Applications/ClickBoom.app
     ```
4. 按提示授予「输入监控」权限，然后随便点几下鼠标即可看到效果。

> 面板默认不再随启动弹出（开机自启时也不会打断登录），从菜单栏图标或 Dock 图标进入即可。

## 🚀 快速开始

### 使用 Xcode

1. 克隆仓库并进入项目目录：

   ```bash
   git clone https://github.com/hhse/clickBoom.git
   cd clickBoom
   ```

2. 使用 Xcode 打开 `clickBoom.xcodeproj`。
3. 选择 `clickBoom` scheme，点击运行。
4. 点击 macOS 菜单栏中的 ClickBoom 图标，可快速开关效果、切换样式并调整常用参数；也可以打开完整控制面板。
5. 在任意应用中点击鼠标，查看点击特效。

### 新颖玩法

- 点击“快捷预设”可以快速切换一整套颜色、粒子和动画参数。
- 调出满意的效果后，在「预设 → 我的预设」点「保存当前」，给它起个名字；之后就能一键套用，右键（或点小叉）可删除。
- 按 `⌃⌥B` 可以在任意 App 里开关特效，不用切回菜单栏。
- 演示或录屏中途想临时关掉效果，用菜单里的「暂停 15 / 30 / 60 分钟」；到点自动恢复，也可以随时点「立即恢复」。
- 开启“随机样式”后，每次点击都会从现有样式中随机选择一种。
- 开启“连续点击放大”后，在 1 秒内连续点击会逐步增加粒子数量、尺寸和扩散范围；停止点击后会自动归零。
- 选择“Emoji 表情”后，在控制面板或菜单栏输入 `✨🔥💖` 这类 Emoji 串；每次点击只弹出一个表情，动画更轻巧。下面的快捷 Emoji 点一下就能加入或移除。

### 命令行构建

```bash
xcodebuild \
  -project clickBoom.xcodeproj \
  -scheme clickBoom \
  -configuration Debug \
  -sdk macosx \
  build
```

如果 `xcode-select -p` 指向 CommandLineTools，需要先 `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`，或者临时指定：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild ...
```

另外，仓库如果放在 iCloud Drive、网盘同步目录等 File Provider 路径下，产物会被写入 FinderInfo 等扩展属性，签名时会报
`resource fork, Finder information, or similar detritus not allowed`。把构建目录指到系统临时目录即可：

```bash
xcodebuild ... -derivedDataPath "${TMPDIR}/clickboom-build"
```

### 打安装包

```bash
./scripts/release.sh          # 输出 dist/ClickBoom-<版本>.dmg（arm64 + x86_64 通用二进制）

PUBLISH=1 ./scripts/release.sh   # 构建完成后直接传到 GitHub Release（需 gh 已登录）
```

推 `v*` 标签时，GitHub Actions 也会自动构建一次并把 DMG 补到 Release；如果 Release 里已经有 DMG 附件，CI 不会覆盖（保留本地签名版本）。

需要正式分发（不再被 Gatekeeper 拦截）时，用 Developer ID 证书签名并公证：

```bash
xcrun notarytool store-credentials clickboom \
  --apple-id <你的 Apple ID> --team-id <TEAMID> --password <App 专用密码>

SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE=clickboom \
./scripts/release.sh
```

## 🎛️ 参数说明

| 参数 | 说明 |
| --- | --- |
| 效果颜色 | 设置当前点击动画的颜色 |
| 数量 | 每次点击生成的粒子数量 |
| 大小 | 火花、光束或彩纸的基础尺寸 |
| 半径 | 动画向外扩散的范围 |
| 持续时间 | 单次点击动画的显示时长 |
| 缩放 | 整体效果的放大或缩小比例 |
| 随机样式 | 每次点击随机选择一种效果样式 |
| 连续点击放大 | 连续点击时逐步增加效果范围 |
| 自定义 Emoji | 输入一个或多个 Emoji，点击时随机弹出一个 |
| 全局快捷键 | `⌃⌥B`，在任意 App 中开关特效 |
| 定时暂停 | 暂停 15 / 30 / 60 分钟后自动恢复 |
| 我的预设 | 保存当前整套参数，同名覆盖，可一键套用或删除 |

## 🧩 项目结构

```text
clickBoom/
├── ContentView.swift       # SwiftUI 控制面板、全局监听和特效渲染
└── Assets.xcassets/        # 应用图标和颜色资源
clickBoom.xcodeproj/        # Xcode 工程文件
scripts/release.sh          # 打包 DMG（通用二进制，可选签名/公证）
```

核心实现集中在 `ContentView.swift`：

- `AppState`：保存开关和特效参数
- `EffectStyle`：管理可用的效果样式
- `EffectEngine`：创建和清理点击粒子
- `EffectOverlayView`：通过 `Canvas` 和 `TimelineView` 绘制动画

## 🗒️ 更新日志

### 1.1.6

- 新增「烟花」「闪电」两种效果；烟花带拖尾和重力下坠，闪电带外发光与亮芯
- 新增「赛博」「烟花」两组内置预设
- 支持保存、套用和删除自定义预设；同名预设直接覆盖
- 新增定时暂停：15 / 30 / 60 分钟后自动恢复，菜单栏和面板均可操作
- 新增全局快捷键 `⌃⌥B`，在任意 App 中开关特效，无需额外权限
- 效果选择改为带说明的图标网格，并新增常用色块和 Emoji 快捷选择
- 菜单栏快速面板新增预览、暂停和「我的预设」，暂停时图标同步变化
- 启动后每天自动检查一次更新，有新版本时菜单栏图标显示小圆点
- 设置改为统一状态管理，控制面板、菜单栏和覆盖层实时同步

### 1.1.5

- 新增右键 / 中键触发（选项里可关闭），演示时右键菜单也有反馈
- 面板顶部新增「预览」按钮：在当前鼠标位置放一次效果，调参不用再切窗口
- 选项里新增「恢复默认设置」，随时回到初始参数
- 菜单栏图标随开关变暗，关闭状态一眼可见
- 跟随系统「减弱动态效果」，开启后收起旋转与摇摆
- 新增 GitHub Actions：推 `v*` 标签会自动构建 DMG 并补到 Release（已有 DMG 附件时不会覆盖）
- `scripts/release.sh` 支持 `PUBLISH=1` 直接上传到 Release

### 1.1.4

- 修复取色偶发失效：目录色、灰度色、广色域色不再被静默重置成白色
- 修复授权「输入监控」后仍需重启 App 才生效的问题
- 启动时不再自动弹出控制面板（开机自启不打断登录），首次安装仍会亮一次，之后点 Dock 图标即可叫回
- 连续点击时的粒子总量加上限，并减少空闲帧里的无效刷新
- 应用名统一为 `ClickBoom`（此前 Dock 与菜单里显示为 `clickBoom`）
- 新增 `scripts/release.sh`：一键打出 arm64 + x86_64 通用 DMG，支持可选签名与公证

### 1.1.3

- 新增水波、星芒、像素、爱心四种效果，支持多显示器与检查更新

## 🔗 开源地址

- GitHub：<https://github.com/hhse/clickBoom>
- 灵感来源：<https://reactbits.dev/animations/click-spark>

欢迎提交 Issue、建议和 Pull Request，一起完善更多点击效果。

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源。
