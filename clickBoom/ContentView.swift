import SwiftUI
import Combine

// MARK: - 点击效果样式
enum ClickEffect: String, CaseIterable, Identifiable {
    case spark
    case ripple
    case burst
    case confetti

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spark: return "放射火花"
        case .ripple: return "扩散波纹"
        case .burst: return "霓虹爆发"
        case .confetti: return "彩纸喷射"
        }
    }

    var icon: String {
        switch self {
        case .spark: return "wand.and.stars"
        case .ripple: return "circle.dotted"
        case .burst: return "sun.max.fill"
        case .confetti: return "party.popper.fill"
        }
    }
}

// MARK: - 1. 全局状态管理 (AppState)
class AppState: ObservableObject {
    static let shared = AppState()
    
    @AppStorage("isEnabled") var isEnabled: Bool = true
    @AppStorage("sparkColorHex") var sparkColorHex: String = "#FFFFFF"
    @AppStorage("sparkSize") var sparkSize: Double = 10.0
    @AppStorage("sparkRadius") var sparkRadius: Double = 15.0
    @AppStorage("sparkCount") var sparkCount: Int = 8
    @AppStorage("duration") var duration: Double = 400.0
    @AppStorage("extraScale") var extraScale: Double = 1.0
    @AppStorage("effectStyle") var effectStyleRaw: String = ClickEffect.spark.rawValue

    var effectStyle: Binding<ClickEffect> {
        Binding(
            get: { ClickEffect(rawValue: self.effectStyleRaw) ?? .spark },
            set: { self.effectStyleRaw = $0.rawValue }
        )
    }

    var sparkColor: Binding<Color> {
        Binding(
            get: { Color(hex: self.sparkColorHex) ?? .white },
            set: { self.sparkColorHex = $0.toHex() ?? "#FFFFFF" }
        )
    }
}

// MARK: - 2. 程序入口
@main
struct ClickSparkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ControlPanelView()
                .frame(width: 380, height: 620) // 固定优雅的比例
                .background(VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow))
        }
        .windowStyle(.hiddenTitleBar) // 隐藏原生丑陋的标题栏
        .windowResizability(.contentSize)
    }
}

// MARK: - 3. 控制面板视图 (Modern UI)
// MARK: - 3. 控制面板视图 (Modern UI)
struct ControlPanelView: View {
    @StateObject var appState = AppState.shared
    
    // 背景渐变
    let bgGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#1A1A2E")!, Color(hex: "#16213E")!]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // 背景层
            bgGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- 顶部标题栏 ---
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Click Spark")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("全局鼠标点击特效")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    
                    // 顶部开关
                    Toggle("", isOn: $appState.isEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        .scaleEffect(0.8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // --- 中间滚动区域 ---
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        
                        // 颜色卡片
                        SectionCard(icon: "paintpalette.fill", title: "外观") {
                            HStack {
                                Text("效果颜色")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                ColorPicker("", selection: appState.sparkColor)
                                    .labelsHidden()
                            }

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Label("效果", systemImage: appState.effectStyle.wrappedValue.icon)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Picker("效果", selection: appState.effectStyle) {
                                    ForEach(ClickEffect.allCases) { effect in
                                        Text(effect.title).tag(effect)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .tint(.white)
                                .frame(width: 120, alignment: .trailing)
                            }
                        }
                        
                        // 粒子属性卡片
                        SectionCard(icon: "sparkles", title: "粒子") {
                            ModernSlider(label: "数量", value: Binding(get: { Double(appState.sparkCount) }, set: { appState.sparkCount = Int($0) }), range: 3...20, icon: "burst.fill", format: "%.0f")
                            Divider().background(Color.white.opacity(0.1))
                            ModernSlider(label: "大小", value: $appState.sparkSize, range: 1...30, icon: "smallcircle.filled.circle", format: "%.0f 像素")
                            Divider().background(Color.white.opacity(0.1))
                            ModernSlider(label: "半径", value: $appState.sparkRadius, range: 5...100, icon: "circle.circle", format: "%.0f 像素")
                        }
                        
                        // 动画属性卡片
                        SectionCard(icon: "timer", title: "动画") {
                            ModernSlider(label: "持续时间", value: $appState.duration, range: 100...2000, icon: "clock.fill", format: "%.0f 毫秒")
                            Divider().background(Color.white.opacity(0.1))
                            ModernSlider(label: "缩放", value: $appState.extraScale, range: 0.5...5.0, icon: "arrow.up.left.and.arrow.down.right", format: "%.1f 倍")
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // --- 底部区域 (新增 TG 按钮) ---
                VStack(spacing: 12) {
                    Divider().background(Color.white.opacity(0.1))
                    
                    // TG 按钮
                    Link(destination: URL(string: "https://t.me/TheBallnow")!) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12))
                            Text("加入 Telegram 社群")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#2AABEE")!, Color(hex: "#229ED9")!], // Telegram 官方蓝渐变
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20) // 胶囊形状
                        .shadow(color: Color(hex: "#229ED9")!.opacity(0.4), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(.plain) // 去除默认点击样式
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() }
                        else { NSCursor.pop() }
                    }

                    // 项目链接
                    HStack(spacing: 12) {
                        Link(destination: URL(string: "https://github.com/hhse/clickBoom")!) {
                            Label("开源地址", systemImage: "chevron.left.forwardslash.chevron.right")
                        }

                        Text("灵感来源")
                            .foregroundColor(.white.opacity(0.4))

                        Link("Reactbits", destination: URL(string: "https://reactbits.dev/animations/click-spark")!)
                            .foregroundColor(.white.opacity(0.6))
                            .underline(true, color: .white.opacity(0.3))
                    }
                    .font(.system(size: 10))
                    .padding(.bottom, 16)
                }
                .background(Color.black.opacity(0.2))
            }
        }
        .colorScheme(.dark)
        .environment(\.locale, Locale(identifier: "zh-Hans"))
    }
}

// MARK: - UI 组件: 现代感滑块行
struct ModernSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let icon: String
    let format: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(String(format: format, value))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Slider(value: $value, in: range)
                .tint(.white)
                .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - UI 组件: 分组卡片
struct SectionCard<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .kerning(1.0) // 增加字间距
            }
            
            VStack(spacing: 12) {
                content
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

// MARK: - 4. 窗口视觉效果 (毛玻璃)
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - 5. 辅助扩展
extension Color {
    init?(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        self.init(red: Double((rgb & 0xFF0000) >> 16) / 255.0, green: Double((rgb & 0x00FF00) >> 8) / 255.0, blue: Double(rgb & 0x0000FF) / 255.0)
    }
    func toHex() -> String? {
        guard let components = self.cgColor?.components, components.count >= 3 else { return nil }
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(components[0]) * 255), lroundf(Float(components[1]) * 255), lroundf(Float(components[2]) * 255))
    }
}

// MARK: - 6. 核心逻辑 (保持不变)
class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow!
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }
        overlayWindow = NSWindow(contentRect: screen.frame, styleMask: [.borderless, .fullSizeContentView], backing: .buffered, defer: false)
        overlayWindow.isOpaque = false; overlayWindow.backgroundColor = .clear; overlayWindow.hasShadow = false; overlayWindow.level = .screenSaver; overlayWindow.ignoresMouseEvents = true
        overlayWindow.contentView = NSHostingView(rootView: SparkOverlayView())
        overlayWindow.makeKeyAndOrderFront(nil)
    }
}

struct Spark: Identifiable {
    let id = UUID()
    var x, y, angle: Double
    var startTime: Date
    var variation: Double
}

class SparkEngine: ObservableObject {
    @Published var sparks: [Spark] = []
    func trigger(at point: CGPoint) {
        guard AppState.shared.isEnabled else { return }
        let now = Date(); var newSparks: [Spark] = []
        let count = AppState.shared.sparkCount
        for i in 0..<count {
            let angle = (2 * .pi * Double(i)) / Double(count)
            // 用稳定的变化值让同一组粒子形状有轻微差异，避免每次都像复制出来的。
            let variation = Double((i * 37) % 100) / 100
            newSparks.append(Spark(x: point.x, y: point.y, angle: angle, startTime: now, variation: variation))
        }
        sparks.append(contentsOf: newSparks)
    }
    func cleanUp(currentTime: Date) {
        let durationSec = AppState.shared.duration / 1000.0
        sparks = sparks.filter { currentTime.timeIntervalSince($0.startTime) < durationSec }
    }
}

struct SparkOverlayView: View {
    @StateObject var engine = SparkEngine()
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let now = context.date
                let durationSec = appState.duration / 1000.0
                let color = appState.sparkColor.wrappedValue
                let sizeVal = appState.sparkSize
                let radius = appState.sparkRadius
                let scale = appState.extraScale
                let effect = appState.effectStyle.wrappedValue
                
                for spark in engine.sparks {
                    let elapsed = now.timeIntervalSince(spark.startTime)
                    if elapsed >= durationSec { continue }
                    let progress = elapsed / durationSec
                    drawEffect(
                        effect,
                        spark: spark,
                        progress: progress,
                        color: color,
                        size: sizeVal,
                        radius: radius,
                        scale: scale,
                        context: ctx
                    )
                }
            }
            .onChange(of: context.date) { _, newDate in engine.cleanUp(currentTime: newDate) }
        }
        .onAppear { setupGlobalMouseListener() }
    }
    
    func setupGlobalMouseListener() {
        NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { _ in triggerSpark(at: NSEvent.mouseLocation) }
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { triggerSpark(at: NSEvent.mouseLocation); return $0 }
    }
    func triggerSpark(at loc: NSPoint) {
        if let h = NSScreen.main?.frame.height { engine.trigger(at: CGPoint(x: loc.x, y: h - loc.y)) }
    }

    private func drawEffect(
        _ effect: ClickEffect,
        spark: Spark,
        progress: Double,
        color: Color,
        size: Double,
        radius: Double,
        scale: Double,
        context: GraphicsContext
    ) {
        let eased = progress * (2 - progress)
        let cosA = cos(spark.angle)
        let sinA = sin(spark.angle)
        let distance = eased * radius * scale
        let fade = max(0, 1 - progress)

        switch effect {
        case .spark:
            let length = size * (1 - eased)
            var path = Path()
            path.move(to: CGPoint(x: spark.x + distance * cosA, y: spark.y + distance * sinA))
            path.addLine(to: CGPoint(x: spark.x + (distance + length) * cosA, y: spark.y + (distance + length) * sinA))
            context.stroke(path, with: .color(color.opacity(fade)), lineWidth: 2.5)

        case .ripple:
            let ringRadius = (radius * scale * 0.15) + (radius * scale * 0.85 * eased) + spark.variation * radius * scale * 0.3
            let ringRect = CGRect(
                x: spark.x - ringRadius,
                y: spark.y - ringRadius,
                width: ringRadius * 2,
                height: ringRadius * 2
            )
            var ring = Path()
            ring.addEllipse(in: ringRect)
            context.stroke(ring, with: .color(color.opacity(fade * 0.7)), lineWidth: max(1.5, size * 0.18))

        case .burst:
            let rayLength = size * (1.2 - eased * 0.8)
            var ray = Path()
            ray.move(to: CGPoint(x: spark.x + distance * 0.35 * cosA, y: spark.y + distance * 0.35 * sinA))
            ray.addLine(to: CGPoint(x: spark.x + (distance + rayLength) * cosA, y: spark.y + (distance + rayLength) * sinA))
            context.stroke(ray, with: .color(color.opacity(fade)), lineWidth: max(2, size * 0.22))

            let dotRadius = max(2, size * 0.28 * fade)
            var dot = Path()
            dot.addEllipse(in: CGRect(x: spark.x - dotRadius, y: spark.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
            context.fill(dot, with: .color(color.opacity(fade * 0.9)))

        case .confetti:
            let fall = eased * radius * scale * 1.35
            let drift = distance * 0.45
            let center = CGPoint(
                x: spark.x + drift * cosA,
                y: spark.y + drift * sinA + fall
            )
            let pieceSize = max(3, size * (0.55 + spark.variation * 0.55) * (1 - eased * 0.25))
            let rotation = spark.angle + progress * (.pi * 1.5) + spark.variation
            let halfWidth = pieceSize * 0.55
            let halfHeight = pieceSize * 0.3
            let cosR = cos(rotation)
            let sinR = sin(rotation)
            let localCorners: [CGPoint] = [
                CGPoint(x: -halfWidth, y: -halfHeight),
                CGPoint(x: halfWidth, y: -halfHeight),
                CGPoint(x: halfWidth, y: halfHeight),
                CGPoint(x: -halfWidth, y: halfHeight)
            ]
            var corners: [CGPoint] = []
            for point in localCorners {
                let rotatedX = point.x * cosR - point.y * sinR
                let rotatedY = point.x * sinR + point.y * cosR
                corners.append(CGPoint(
                    x: center.x + rotatedX,
                    y: center.y + rotatedY
                ))
            }
            var piece = Path()
            piece.move(to: corners[0])
            corners.dropFirst().forEach { piece.addLine(to: $0) }
            piece.closeSubpath()
            context.fill(piece, with: .color(color.opacity(fade)))
        }
    }
}
