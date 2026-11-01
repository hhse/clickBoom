# clickBoom

一个轻量、原生的 macOS 全局鼠标点击特效工具。它会监听鼠标点击，并在点击位置绘制即时动画，让演示、录屏、直播和日常操作更有反馈感。

项目使用 SwiftUI 和 macOS 原生 API 编写，不依赖第三方运行库。

## ✨ 功能特性

- 全局监听鼠标左键点击
- 9 种可切换的点击效果：
  - 火花：短线条向外散开
  - 圆环：一段圆弧从点击位置展开
  - 光线：几条细光线快速划过
  - 彩纸：小块彩纸轻轻飘开
  - 表情：点击弹出自定义 Emoji，带轻微弹性、漂浮和旋转动画
  - 水波：三圈涟漪依次向外扩散、逐圈变淡
  - 星芒：四长四短的尖细星芒 + 中心高光，像镜头光晕
  - 像素：8-bit 小方块四散旋转、边飞边缩小
  - 爱心：小爱心错峰上浮，带轻微摇摆与旋转
- 支持自定义效果颜色
- 支持输入一个或多个自定义 Emoji，多个 Emoji 会在每次点击时随机选择
- 内置 4 组快捷预设：默认、蓝光、圆环、彩纸
- 支持调整粒子数量、大小、扩散半径、动画时长和缩放比例
- Emoji 模式支持在控制面板或菜单栏直接编辑自定义表情
- 菜单栏提供快速面板，可直接开关效果、切换样式、改颜色和调整常用参数
- 随机样式：每次点击自动抽取一种样式
- 连续点击放大：短时间连续点击会逐步增加粒子数量和范围
- 支持开机自启（基于系统登录项，可随时在控制面板或菜单栏开关）
- 自动检测「输入监控」权限，未授权时直接在面板里提示并一键跳转设置，授权后立即生效、无需重启
- 支持多显示器：覆盖层铺满所有屏幕，副屏/竖屏点击同样有效，插拔显示器自动适配
- 启动时只留在菜单栏，不弹面板（开机自启也不会打断登录），点 Dock 图标可随时叫回
- 空闲时暂停动画渲染，不点击就不占绘图资源
- 控制面板可拖拽调整窗口大小
- 内置「检查更新」，直接对比 GitHub 上最新 Release
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
- 开启“随机样式”后，每次点击都会从现有样式中随机选择一种。
- 开启“连续点击放大”后，在 1 秒内连续点击会逐步增加粒子数量、尺寸和扩散范围；停止点击后会自动归零。
- 选择“Emoji 表情”后，在控制面板或菜单栏输入 `✨🔥💖` 这类 Emoji 串；每次点击只弹出一个表情，动画更轻巧。

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
```

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
