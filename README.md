# clickBoom

一个轻量、原生的 macOS 全局鼠标点击特效工具。它会监听鼠标点击，并在点击位置绘制即时动画，让演示、录屏、直播和日常操作更有反馈感。

项目使用 SwiftUI 和 macOS 原生 API 编写，不依赖第三方运行库。

## ✨ 功能特性

- 全局监听鼠标左键点击
- 4 种可切换的点击效果：
  - 放射火花：经典的向外迸射线条
  - 扩散波纹：从点击位置扩散的圆环
  - 霓虹爆发：光束与中心亮点组合的爆发效果
  - 彩纸喷射：带旋转和下落感的彩纸粒子
- 支持自定义效果颜色
- 内置 4 组快捷预设：轻盈、霓虹、水波、派对
- 支持调整粒子数量、大小、扩散半径、动画时长和缩放比例
- 菜单栏提供快速面板，可直接开关效果、切换样式、改颜色和调整常用参数
- 随机效果模式：每次点击自动抽取不同特效
- 连击增强模式：短时间连续点击会逐步放大粒子规模，并显示当前连击倍数
- 设置会自动保存，下次启动时继续使用
- 使用透明悬浮层绘制，不影响鼠标正常操作
- 原生 SwiftUI 界面，轻量且易于扩展

## 🖥️ 系统要求

- macOS 26.0 或更高版本
- Xcode 26.0 或更高版本（用于编译）

首次运行时，如果系统提示权限请求，请前往“系统设置 → 隐私与安全性”，为应用开启所需的辅助功能或输入监控权限。该权限用于接收其他应用中的全局鼠标点击事件。

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
- 开启“随机效果”后，每次点击都会从现有特效中随机选择一种。
- 开启“连击增强”后，在 1 秒内连续点击会逐步增加粒子数量、尺寸和扩散范围；停止点击后连击会自动归零。

### 命令行构建

```bash
xcodebuild \
  -project clickBoom.xcodeproj \
  -scheme clickBoom \
  -configuration Debug \
  -sdk macosx \
  build
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
| 随机效果 | 每次点击随机选择一种特效 |
| 连击增强 | 连续点击时逐步提升效果强度 |

## 🧩 项目结构

```text
clickBoom/
├── ContentView.swift       # SwiftUI 控制面板、全局监听和特效渲染
└── Assets.xcassets/        # 应用图标和颜色资源
clickBoom.xcodeproj/        # Xcode 工程文件
```

核心实现集中在 `ContentView.swift`：

- `AppState`：保存开关和特效参数
- `ClickEffect`：管理可用的特效类型
- `SparkEngine`：创建和清理点击粒子
- `SparkOverlayView`：通过 `Canvas` 和 `TimelineView` 绘制动画

## 🔗 开源地址

- GitHub：<https://github.com/hhse/clickBoom>
- 灵感来源：<https://reactbits.dev/animations/click-spark>

欢迎提交 Issue、建议和 Pull Request，一起完善更多点击效果。

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源。
