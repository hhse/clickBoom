import SwiftUI
import Combine
import CoreGraphics
import ServiceManagement

// MARK: - 点击效果样式
enum EffectStyle: String, CaseIterable, Identifiable {
    case spark
    case ripple
    case burst
    case confetti
    case emoji
    case wave
    case starflare
    case pixel
    case hearts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spark: return "火花"
        case .ripple: return "圆环"
        case .burst: return "光线"
        case .confetti: return "彩纸"
        case .emoji: return "表情"
        case .wave: return "水波"
        case .starflare: return "星芒"
        case .pixel: return "像素"
        case .hearts: return "爱心"
        }
    }

    var icon: String {
        switch self {
        case .spark: return "sparkles"
        case .ripple: return "circle.dotted"
        case .burst: return "line.3.horizontal"
        case .confetti: return "square.grid.2x2"
        case .emoji: return "face.smiling"
        case .wave: return "water.waves"
        case .starflare: return "sparkle"
        case .pixel: return "square.grid.3x3.fill"
        case .hearts: return "heart.fill"
        }
    }
}

enum EffectPreset: String, CaseIterable, Identifiable {
    case standard
    case blue
    case ring
    case confetti

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "默认"
        case .blue: return "蓝光"
        case .ring: return "圆环"
        case .confetti: return "彩纸"
        }
    }

    var icon: String {
        switch self {
        case .standard: return "sparkles"
        case .blue: return "circle.fill"
        case .ring: return "circle.dotted"
        case .confetti: return "square.grid.2x2"
        }
    }

    var settings: Settings {
        switch self {
        case .standard:
            return Settings(effect: .spark, color: "#FFFFFF", count: 6, size: 6, radius: 12, durationMs: 280, scale: 0.85)
        case .blue:
            return Settings(effect: .burst, color: "#66E8FF", count: 7, size: 7, radius: 18, durationMs: 360, scale: 0.9)
        case .ring:
            return Settings(effect: .ripple, color: "#63F2CE", count: 6, size: 7, radius: 24, durationMs: 480, scale: 0.85)
        case .confetti:
            return Settings(effect: .confetti, color: "#FF77C8", count: 7, size: 6, radius: 20, durationMs: 520, scale: 0.9)
        }
    }

    struct Settings {
        let effect: EffectStyle
        let color: String
        let count: Int
        let size: Double
        let radius: Double
        let durationMs: Double
        let scale: Double
    }
}

// MARK: - 1. 全局状态管理 (AppState)
class AppState: ObservableObject {
    static let shared = AppState()
    
    @AppStorage("isEnabled") var isEnabled: Bool = true
    @AppStorage("sparkColorHex") var effectColorHex: String = "#FFFFFF"
    @AppStorage("sparkSize") var particleSize: Double = 10.0
    @AppStorage("sparkRadius") var particleRadius: Double = 15.0
    @AppStorage("sparkCount") var particleCount: Int = 8
    @AppStorage("duration") var durationMs: Double = 400.0
    @AppStorage("extraScale") var scale: Double = 1.0
    @AppStorage("effectStyle") var effectStyleRaw: String = EffectStyle.spark.rawValue
    @AppStorage("randomEffectEnabled") var randomEffectEnabled: Bool = false
    @AppStorage("comboBoostEnabled") var comboBoostEnabled: Bool = false
    @AppStorage("customEmoji") var customEmoji: String = "✨"
    @Published var comboCount: Int = 0

    var effectStyle: Binding<EffectStyle> {
        Binding(
            get: { EffectStyle(rawValue: self.effectStyleRaw) ?? .spark },
            set: { self.effectStyleRaw = $0.rawValue }
        )
    }

    var effectColor: Binding<Color> {
        Binding(
            get: { Color(hex: self.effectColorHex) ?? .white },
            set: { self.effectColorHex = $0.toHex() ?? "#FFFFFF" }
        )
    }

    var emojiChoices: [String] {
        let choices = customEmoji
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return choices.isEmpty ? ["✨"] : choices
    }

    func apply(_ preset: EffectPreset) {
        let settings = preset.settings
        effectStyleRaw = settings.effect.rawValue
        effectColorHex = settings.color
        particleCount = settings.count
        particleSize = settings.size
        particleRadius = settings.radius
        durationMs = settings.durationMs
        scale = settings.scale
        randomEffectEnabled = false
        comboBoostEnabled = false
        comboCount = 0
    }
}

// MARK: - 应用信息
enum AppInfo {
    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.3"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "5"
    }

    static var version: String {
        "\(shortVersion) (\(buildNumber))"
    }
}

// MARK: - 检查更新
@MainActor
final class UpdateChecker: ObservableObject {
    enum Status: Equatable {
        case idle
        case checking
        case latest
        case available(String, URL?)
        case failed(String)
    }

    static let shared = UpdateChecker()

    @Published private(set) var status: Status = .idle

    private let latestURL = URL(string: "https://api.github.com/repos/hhse/clickBoom/releases/latest")!

    func check() {
        guard status != .checking else { return }
        status = .checking

        var request = URLRequest(url: latestURL)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            let result: Status
            if let data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tag = json["tag_name"] as? String {
                let remote = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
                let page = (json["html_url"] as? String).flatMap(URL.init(string:))
                result = Self.isNewer(remote, than: AppInfo.shortVersion)
                    ? .available(remote, page)
                    : .latest
            } else if let error {
                result = .failed(error.localizedDescription)
            } else {
                result = .failed("无法解析服务器响应")
            }
            DispatchQueue.main.async { self?.status = result }
        }.resume()
    }

    func openDownloadPage() {
        if case let .available(_, url) = status, let url {
            NSWorkspace.shared.open(url)
        } else {
            NSWorkspace.shared.open(URL(string: "https://github.com/hhse/clickBoom/releases")!)
        }
    }

    /// 逐段比较版本号，缺位补 0
    nonisolated static func isNewer(_ remote: String, than local: String) -> Bool {
        let r = remote.split(separator: ".").map { Int($0) ?? 0 }
        let l = local.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }
}

// MARK: - 开机自启
@MainActor
final class LaunchAtLogin: ObservableObject {
    static let shared = LaunchAtLogin()

    @Published private(set) var isEnabled = false
    @Published private(set) var requiresApproval = false
    @Published private(set) var message: String?

    init() { refresh() }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        requiresApproval = status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) {
        message = nil
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            message = "设置失败：\(error.localizedDescription)\n请先把 ClickBoom 拖进「应用程序」再试。"
        }
        refresh()
        if requiresApproval {
            message = "已登记，还需要在「系统设置 → 通用 → 登录项」里允许。"
        }
    }

    func openLoginItemsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 输入监控权限
@MainActor
final class InputPermission: ObservableObject {
    static let shared = InputPermission()

    @Published private(set) var isGranted = CGPreflightListenEventAccess()

    func refresh() {
        isGranted = CGPreflightListenEventAccess()
    }

    func request() {
        _ = CGRequestListenEventAccess()
        refresh()
    }

    func openSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - 2. 程序入口
@main
struct ClickBoomApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Window("ClickBoom", id: "control-panel") {
            ControlPanelView()
                .frame(minWidth: 400, idealWidth: 440, minHeight: 660, idealHeight: 820)
                .background(VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow))
        }
        .windowStyle(.hiddenTitleBar) // 隐藏原生丑陋的标题栏
        .windowResizability(.contentMinSize) // 允许自由拖拽改变大小

        MenuBarExtra("ClickBoom", systemImage: "sparkles") {
            MenuBarQuickPanel()
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - 菜单栏快速控制面板
struct MenuBarQuickPanel: View {
    @Environment(\.openWindow) private var openWindow
    @StateObject private var appState = AppState.shared
    @StateObject private var loginItem = LaunchAtLogin.shared
    @StateObject private var permission = InputPermission.shared
    @StateObject private var update = UpdateChecker.shared

    private var particleCount: Binding<Double> {
        Binding(
            get: { Double(appState.particleCount) },
            set: { appState.particleCount = Int($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ClickBoom")
                        .font(.system(size: 14, weight: .semibold))
                    Text("鼠标点击特效")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("启用", isOn: $appState.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .help("开启或关闭点击特效")
            }

            Divider()

            if !permission.isGranted {
                Button {
                    permission.request()
                } label: {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("缺少「输入监控」权限，点击特效不会触发。点这里开启。")
                            .font(.system(size: 11))
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Divider()
            }

            Menu {
                ForEach(EffectPreset.allCases) { preset in
                    Button {
                        appState.apply(preset)
                    } label: {
                        Label(preset.title, systemImage: preset.icon)
                    }
                }
            } label: {
                Label("预设", systemImage: "slider.horizontal.3")
            }

            Picker("效果", selection: appState.effectStyle) {
                ForEach(EffectStyle.allCases) { effect in
                    Label(effect.title, systemImage: effect.icon)
                        .tag(effect)
                }
            }

            TextField("自定义 Emoji", text: $appState.customEmoji)
                .textFieldStyle(.roundedBorder)
                .help("输入一个或多个 Emoji，点击时会随机弹出")

            ColorPicker("效果颜色", selection: appState.effectColor, supportsOpacity: false)

            QuickSlider(
                label: "粒子数量",
                value: particleCount,
                range: 3...20,
                step: 1,
                format: "%.0f"
            )
            QuickSlider(
                label: "粒子大小",
                value: $appState.particleSize,
                range: 1...30,
                step: 1,
                format: "%.0f 像素"
            )
            QuickSlider(
                label: "动画时长",
                value: $appState.durationMs,
                range: 100...2000,
                step: 50,
                format: "%.0f 毫秒"
            )
            QuickSlider(
                label: "扩散半径",
                value: $appState.particleRadius,
                range: 5...100,
                step: 5,
                format: "%.0f 像素"
            )
            QuickSlider(
                label: "缩放比例",
                value: $appState.scale,
                range: 0.5...5.0,
                step: 0.1,
                format: "%.1f 倍"
            )

            Toggle("随机样式", isOn: $appState.randomEffectEnabled)
            Toggle("连续点击放大", isOn: $appState.comboBoostEnabled)
            if appState.comboBoostEnabled, appState.comboCount > 1 {
                Label("连击 ×\(appState.comboCount)", systemImage: "flame.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            }

            Divider()

            Button {
                openWindow(id: "control-panel")
            } label: {
                Label("打开完整控制面板", systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Link(destination: URL(string: "https://github.com/hhse/clickBoom")!) {
                Label("GitHub 开源地址", systemImage: "chevron.left.forwardslash.chevron.right")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            Toggle("开机自启", isOn: Binding(
                get: { loginItem.isEnabled },
                set: { loginItem.setEnabled($0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)

            if let message = loginItem.message {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if loginItem.requiresApproval {
                Button("去「登录项」允许") { loginItem.openLoginItemsSettings() }
                    .buttonStyle(.link)
                    .font(.system(size: 10))
            }

            Divider()

            HStack(spacing: 8) {
                Button {
                    UpdateChecker.shared.check()
                } label: {
                    Label("检查更新", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(update.status == .checking)

                Spacer()

                Text(updateStatusText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                Text("v\(AppInfo.version)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            Button(role: .destructive) {
                NSApp.terminate(nil)
            } label: {
                Label("退出 ClickBoom", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(width: 360)
        .environment(\.locale, Locale(identifier: "zh-Hans"))
    }

    private var updateStatusText: String {
        switch update.status {
        case .idle: return ""
        case .checking: return "检查中…"
        case .latest: return "已是最新"
        case .available(let version, _): return "有新版本 \(version)"
        case .failed: return "检查失败"
        }
    }
}

struct QuickSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: format, value))
                    .monospacedDigit()
            }
            .font(.system(size: 11))

            Slider(value: $value, in: range, step: step)
                .controlSize(.small)
        }
    }
}

// MARK: - 3. 控制面板视图 (Modern UI)
// MARK: - 3. 控制面板视图 (Modern UI)
struct ControlPanelView: View {
    @StateObject var appState = AppState.shared
    @StateObject private var loginItem = LaunchAtLogin.shared
    @StateObject private var permission = InputPermission.shared
    @StateObject private var update = UpdateChecker.shared
    
    @ViewBuilder
    private var updateStatusRow: some View {
        switch update.status {
        case .idle:
            EmptyView()
        case .checking:
            Text("正在检查最新版本…")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
        case .latest:
            Label("已是最新版本", systemImage: "checkmark.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(.green)
        case .available(let version, _):
            HStack(spacing: 8) {
                Label("发现新版本 \(version)", systemImage: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                Spacer()
                Button("前往下载") { update.openDownloadPage() }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
            }
        case .failed(let message):
            Text("检查失败：\(message)")
                .font(.system(size: 11))
                .foregroundColor(.red.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

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
                        Text("ClickBoom")
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
                                ColorPicker("", selection: appState.effectColor)
                                    .labelsHidden()
                            }

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Label("效果", systemImage: appState.effectStyle.wrappedValue.icon)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Picker("效果", selection: appState.effectStyle) {
                                    ForEach(EffectStyle.allCases) { effect in
                                        Text(effect.title).tag(effect)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .tint(.white)
                                .frame(width: 120, alignment: .trailing)
                            }

                            if appState.effectStyle.wrappedValue == .emoji {
                                HStack(spacing: 10) {
                                    Label("自定义 Emoji", systemImage: "face.smiling")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    TextField("例如：✨🔥💖", text: $appState.customEmoji)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 130)
                                }
                            }
                        }

                        SectionCard(icon: "slider.horizontal.3", title: "预设") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(EffectPreset.allCases) { preset in
                                    PresetButton(preset: preset) {
                                        appState.apply(preset)
                                    }
                                }
                            }
                        }
                        
                        // 粒子属性卡片
                        SectionCard(icon: "sparkles", title: "粒子") {
                            ModernSlider(label: "数量", value: Binding(get: { Double(appState.particleCount) }, set: { appState.particleCount = Int($0) }), range: 3...20, icon: "burst.fill", format: "%.0f")
                            Divider().background(Color.white.opacity(0.1))
                            ModernSlider(label: "大小", value: $appState.particleSize, range: 1...30, icon: "smallcircle.filled.circle", format: "%.0f 像素")
                            Divider().background(Color.white.opacity(0.1))
                            ModernSlider(label: "半径", value: $appState.particleRadius, range: 5...100, icon: "circle.circle", format: "%.0f 像素")
                        }
                        
                        // 动画属性卡片
                        SectionCard(icon: "timer", title: "动画") {
                            ModernSlider(label: "持续时间", value: $appState.durationMs, range: 100...2000, icon: "clock.fill", format: "%.0f 毫秒")
                            Divider().background(Color.white.opacity(0.1))
                            ModernSlider(label: "缩放", value: $appState.scale, range: 0.5...5.0, icon: "arrow.up.left.and.arrow.down.right", format: "%.1f 倍")
                        }

                        SectionCard(icon: "gearshape", title: "选项") {
                            Toggle("随机样式", isOn: $appState.randomEffectEnabled)
                                .toggleStyle(.switch)
                                .tint(.cyan)
                            Text("每次点击自动抽取一种效果")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))

                            Divider().background(Color.white.opacity(0.1))

                            Toggle("连续点击放大", isOn: $appState.comboBoostEnabled)
                                .toggleStyle(.switch)
                                .tint(.orange)
                            Text("短时间连续点击会逐步放大效果")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))
                            if appState.comboBoostEnabled, appState.comboCount > 1 {
                                Label("当前连击 ×\(appState.comboCount)", systemImage: "flame.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                        }

                        SectionCard(icon: "gearshape.2", title: "系统") {
                            Toggle("开机自启", isOn: Binding(
                                get: { loginItem.isEnabled },
                                set: { loginItem.setEnabled($0) }
                            ))
                            .toggleStyle(.switch)
                            .tint(.green)

                            Text("登录 macOS 时自动启动 ClickBoom")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))

                            if let message = loginItem.message {
                                Text(message)
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if loginItem.requiresApproval {
                                Button("去「登录项」允许") { loginItem.openLoginItemsSettings() }
                                    .buttonStyle(.link)
                                    .font(.system(size: 11))
                            }

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Label("输入监控权限",
                                      systemImage: permission.isGranted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(permission.isGranted ? "已开启" : "未开启")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(permission.isGranted ? .green : .orange)
                            }

                            if !permission.isGranted {
                                Button {
                                    permission.request()
                                } label: {
                                    Label("开启输入监控", systemImage: "arrow.up.forward.app")
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                            }

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Label("版本", systemImage: "tag")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text(AppInfo.version)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Label("检查更新", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Button {
                                    update.check()
                                } label: {
                                    Text(update.status == .checking ? "检查中…" : "检查")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(update.status == .checking)
                            }

                            updateStatusRow
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
                            Label("GitHub 开源地址", systemImage: "chevron.left.forwardslash.chevron.right")
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

struct PresetButton: View {
    let preset: EffectPreset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: preset.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(preset.title)
                    .font(.system(size: 12, weight: .medium))
                Spacer(minLength: 0)
            }
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.07))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
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
/// 所有屏幕的并集（全局坐标，原点在主屏左下角）。
/// 单块透明覆盖层铺满全部屏幕，副屏和竖屏都能落点。
enum ScreenUnion {
    static var frame: CGRect {
        let screens = NSScreen.screens
        guard let first = screens.first else { return .zero }
        return screens.dropFirst().reduce(first.frame) { $0.union($1.frame) }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlayWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 显式设置 Dock 图标：老版本图标资源为空，系统会缓存成「白纸」，
        // 启动时用包内 AppIcon.icns 覆盖，确保 Dock 一定显示新图标。
        NSApp.setActivationPolicy(.regular)
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }

        layoutOverlay()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    /// 插拔显示器、改分辨率、调整排列方式时重建覆盖层尺寸
    @objc private func screenParametersChanged() {
        layoutOverlay()
    }

    private func layoutOverlay() {
        let frame = ScreenUnion.frame
        guard frame.width > 0, frame.height > 0 else { return }

        if let window = overlayWindow {
            window.setFrame(frame, display: true)
            return
        }

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        window.contentView = NSHostingView(rootView: EffectOverlayView())
        window.setFrame(frame, display: false)
        window.orderFrontRegardless()
        overlayWindow = window
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // 从系统设置改完权限 / 登录项切回来时刷新状态
        InputPermission.shared.refresh()
        LaunchAtLogin.shared.refresh()
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x, y, angle: Double
    var startTime: Date
    var variation: Double
    var effect: EffectStyle
    var intensity: Double
    var emoji: String
}

class EffectEngine: ObservableObject {
    @Published var particles: [Particle] = []
    private var lastClickTime = Date.distantPast
    private var comboLevel = 0

    func trigger(at point: CGPoint) {
        let state = AppState.shared
        guard state.isEnabled else { return }

        let now = Date()
        if state.comboBoostEnabled {
            comboLevel = now.timeIntervalSince(lastClickTime) <= 1.0 ? min(comboLevel + 1, 8) : 1
            state.comboCount = comboLevel
            lastClickTime = now

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
                guard let self, self.lastClickTime == now else { return }
                self.comboLevel = 0
                state.comboCount = 0
            }
        } else {
            comboLevel = 0
            state.comboCount = 0
        }

        let intensity = state.comboBoostEnabled
            ? min(1 + Double(max(comboLevel - 1, 0)) * 0.08, 1.4)
            : 1.0
        let effect = state.randomEffectEnabled
            ? EffectStyle.allCases.randomElement() ?? .spark
            : state.effectStyle.wrappedValue
        let count = effect == .emoji
            ? 1
            : min(32, Int((Double(state.particleCount) * intensity).rounded()))
        let emoji = effect == .emoji ? (state.emojiChoices.randomElement() ?? "✨") : ""
        var newParticles: [Particle] = []
        for i in 0..<count {
            let angle = (2 * .pi * Double(i)) / Double(count)
            // 用稳定的变化值让同一组粒子形状有轻微差异，避免每次都像复制出来的。
            let variation = Double((i * 37) % 100) / 100
            newParticles.append(Particle(
                x: point.x,
                y: point.y,
                angle: angle,
                startTime: now,
                variation: variation,
                effect: effect,
                intensity: intensity,
                emoji: emoji
            ))
        }
        particles.append(contentsOf: newParticles)
    }
    func cleanUp(currentTime: Date) {
        let durationSec = AppState.shared.durationMs / 1000.0
        particles = particles.filter { currentTime.timeIntervalSince($0.startTime) < durationSec }
    }
}

struct EffectOverlayView: View {
    @StateObject var engine = EffectEngine()
    @StateObject private var mouseMonitor = GlobalMouseMonitor()
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        // 没有粒子时暂停时间线，避免空闲状态一直 60fps 重绘（省电）
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: engine.particles.isEmpty)) { context in
            Canvas { ctx, size in
                let now = context.date
                let durationSec = appState.durationMs / 1000.0
                let color = appState.effectColor.wrappedValue
                let sizeVal = appState.particleSize
                let radius = appState.particleRadius
                let scale = appState.scale
                
                for particle in engine.particles {
                    let elapsed = now.timeIntervalSince(particle.startTime)
                    if elapsed >= durationSec { continue }
                    let progress = elapsed / durationSec
                    drawEffect(
                        particle.effect,
                        particle: particle,
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
        .onAppear { mouseMonitor.start(engine: engine) }
        .onDisappear { mouseMonitor.stop() }
    }

    /// 以 (0,0) 为中心、边长 size 的爱心路径
    private func heartPath(size: CGFloat) -> Path {
        let w = size
        let h = size
        let ox = -w / 2
        let oy = -h / 2
        var path = Path()
        path.move(to: CGPoint(x: ox + w * 0.5, y: oy + h * 0.30))
        path.addCurve(
            to: CGPoint(x: ox + 0.0, y: oy + h * 0.30),
            control1: CGPoint(x: ox + w * 0.36, y: oy + h * 0.02),
            control2: CGPoint(x: ox + 0.0, y: oy + h * 0.04)
        )
        path.addCurve(
            to: CGPoint(x: ox + w * 0.5, y: oy + h * 1.0),
            control1: CGPoint(x: ox + 0.0, y: oy + h * 0.62),
            control2: CGPoint(x: ox + w * 0.30, y: oy + h * 0.80)
        )
        path.addCurve(
            to: CGPoint(x: ox + w * 1.0, y: oy + h * 0.30),
            control1: CGPoint(x: ox + w * 0.70, y: oy + h * 0.80),
            control2: CGPoint(x: ox + w * 1.0, y: oy + h * 0.62)
        )
        path.addCurve(
            to: CGPoint(x: ox + w * 0.5, y: oy + h * 0.30),
            control1: CGPoint(x: ox + w * 1.0, y: oy + h * 0.04),
            control2: CGPoint(x: ox + w * 0.64, y: oy + h * 0.02)
        )
        return path
    }

    private func drawEffect(
        _ effect: EffectStyle,
        particle: Particle,
        progress: Double,
        color: Color,
        size: Double,
        radius: Double,
        scale: Double,
        context: GraphicsContext
    ) {
        let eased = progress * (2 - progress)
        let cosA = cos(particle.angle)
        let sinA = sin(particle.angle)
        let boostedSize = size * particle.intensity
        let distance = eased * radius * scale * particle.intensity
        let fade = max(0, 1 - progress)

        switch effect {
        case .spark:
            let length = boostedSize * (1 - eased)
            var path = Path()
            path.move(to: CGPoint(x: particle.x + distance * cosA, y: particle.y + distance * sinA))
            path.addLine(to: CGPoint(x: particle.x + (distance + length) * cosA, y: particle.y + (distance + length) * sinA))
            context.stroke(path, with: .color(color.opacity(fade)), lineWidth: 2.5)

        case .ripple:
            let expandedRadius = radius * scale * particle.intensity
            let ringRadius = (expandedRadius * 0.15) + (expandedRadius * 0.85 * eased) + particle.variation * expandedRadius * 0.3
            var ring = Path()
            let arcSize = 0.32 + particle.variation * 0.18
            ring.addArc(
                center: CGPoint(x: particle.x, y: particle.y),
                radius: ringRadius,
                startAngle: .radians(particle.angle - arcSize),
                endAngle: .radians(particle.angle + arcSize),
                clockwise: false
            )
            context.stroke(
                ring,
                with: .color(color.opacity(fade * 0.75)),
                style: StrokeStyle(lineWidth: max(1.25, boostedSize * 0.16), lineCap: .round)
            )

        case .burst:
            let rayLength = boostedSize * (1.2 - eased * 0.8)
            var ray = Path()
            ray.move(to: CGPoint(x: particle.x + distance * 0.35 * cosA, y: particle.y + distance * 0.35 * sinA))
            ray.addLine(to: CGPoint(x: particle.x + (distance + rayLength) * cosA, y: particle.y + (distance + rayLength) * sinA))
            context.stroke(ray, with: .color(color.opacity(fade)), lineWidth: max(2, boostedSize * 0.22))

            if particle.variation < 0.05 {
                let dotRadius = max(1.5, boostedSize * 0.2 * fade)
                var dot = Path()
                dot.addEllipse(in: CGRect(x: particle.x - dotRadius, y: particle.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
                context.fill(dot, with: .color(color.opacity(fade * 0.85)))
            }

        case .confetti:
            let fall = eased * radius * scale * particle.intensity * 1.35
            let drift = distance * 0.45
            let center = CGPoint(
                x: particle.x + drift * cosA,
                y: particle.y + drift * sinA + fall
            )
            let pieceSize = max(3, boostedSize * (0.55 + particle.variation * 0.55) * (1 - eased * 0.25))
            let rotation = particle.angle + progress * (.pi * 1.5) + particle.variation
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

        case .wave:
            // 三条环依次向外扩散；只让 0 号粒子负责画，避免多圈重叠成一团
            if particle.variation < 0.001 {
                let maxRadius = radius * scale * particle.intensity
                for index in 0..<3 {
                    let phase = (progress + Double(index) / 3.0)
                        .truncatingRemainder(dividingBy: 1.0)
                    let ringRadius = maxRadius * (0.10 + 0.95 * phase)
                    var wave = Path()
                    wave.addEllipse(in: CGRect(
                        x: particle.x - ringRadius,
                        y: particle.y - ringRadius,
                        width: ringRadius * 2,
                        height: ringRadius * 2
                    ))
                    context.stroke(
                        wave,
                        with: .color(color.opacity((1 - phase) * 0.68)),
                        lineWidth: max(1.5, boostedSize * 0.22) * (1 - phase * 0.45)
                    )
                }
            }

        case .starflare:
            // 尖细星芒：中心宽、尖端收拢的三角，外加一个只画一次的核心高光
            let flareLength = radius * scale * particle.intensity
                * (0.55 + particle.variation * 0.75)
                * (0.35 + eased * 0.85)
            let baseWidth = boostedSize * 0.24 * (1 - eased * 0.2)
            let normalX = -sinA
            let normalY = cosA
            let tip = CGPoint(
                x: particle.x + flareLength * cosA,
                y: particle.y + flareLength * sinA
            )
            var spike = Path()
            spike.move(to: CGPoint(x: particle.x + normalX * baseWidth,
                                   y: particle.y + normalY * baseWidth))
            spike.addLine(to: tip)
            spike.addLine(to: CGPoint(x: particle.x - normalX * baseWidth,
                                      y: particle.y - normalY * baseWidth))
            spike.closeSubpath()
            context.fill(spike, with: .color(color.opacity(fade)))

            if particle.variation < 0.001 {
                let coreRadius = max(2, boostedSize * 0.85) * (0.75 + 0.25 * eased)
                var core = Path()
                core.addEllipse(in: CGRect(
                    x: particle.x - coreRadius,
                    y: particle.y - coreRadius,
                    width: coreRadius * 2,
                    height: coreRadius * 2
                ))
                context.fill(core, with: .color(color.opacity(fade * 0.95)))
            }

        case .pixel:
            // 8-bit 小方块：边飞边旋转、边缩小
            let travel = eased * radius * scale * particle.intensity
                * (0.35 + particle.variation * 0.95)
            let side = max(2.5, boostedSize * (0.65 + particle.variation * 0.55) * (1 - eased * 0.25))
            var pixelContext = context
            pixelContext.translateBy(
                x: particle.x + travel * cosA,
                y: particle.y + travel * sinA
            )
            pixelContext.rotate(by: .radians(progress * 3.2 + particle.variation * 6.3))
            let square = Path(CGRect(x: -side / 2, y: -side / 2, width: side, height: side))
            pixelContext.fill(square, with: .color(color.opacity(fade)))

        case .hearts:
            // 爱心上浮 + 轻微摇摆旋转，按 variation 错峰起飞避免一开始挤成一坨
            let localP = min(1, progress * 1.12 + particle.variation * 0.10)
            let easedHeart = localP * (2 - localP)
            let spread = radius * scale * particle.intensity
            let lift = easedHeart * spread * 1.8
            let sway = sin(localP * .pi * 2.4 + particle.variation * 4) * spread * 0.22
            let heartX = particle.x + cosA * spread * 1.05 * easedHeart + sway
            let heartY = particle.y + sinA * spread * 0.28 * easedHeart - lift
                - particle.variation * boostedSize * 0.9
            let heartSize = max(9, boostedSize * 2.2 * (0.70 + 0.40 * (1 - easedHeart)))
            var heartContext = context
            heartContext.opacity = fade * 0.95
            heartContext.translateBy(x: heartX, y: heartY)
            heartContext.rotate(by: .radians(sin(localP * .pi * 1.6 + particle.variation * 3) * 0.32))
            heartContext.fill(heartPath(size: heartSize), with: .color(color))

        case .emoji:
            let popProgress = min(1, progress / 0.2)
            let popEase = 1 - pow(1 - popProgress, 3)
            let lift = eased * radius * scale * 0.65
            let sway = sin(progress * .pi * 2.2 + particle.variation * 5) * size * 0.35 * fade
            let emojiScale = max(0.01, (0.45 + popEase * 0.55) * particle.intensity)
            let rotation = sin(progress * .pi * 1.4 + particle.variation * 3) * 0.16
            var emojiContext = context
            emojiContext.opacity = fade
            emojiContext.translateBy(
                x: particle.x + sway,
                y: particle.y - lift - particle.variation * size * 0.25
            )
            emojiContext.rotate(by: .radians(rotation))
            emojiContext.scaleBy(x: emojiScale, y: emojiScale)
            emojiContext.draw(
                Text(particle.emoji)
                    .font(.system(size: max(18, size * 2.2), weight: .regular)),
                at: .zero,
                anchor: .center
            )
        }
    }
}

@MainActor
final class GlobalMouseMonitor: ObservableObject {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    /// 全局坐标（左下原点）→ 覆盖层视图坐标（左上原点，覆盖全部屏幕）
    private static func overlayPoint() -> CGPoint? {
        let union = ScreenUnion.frame
        guard union.height > 0 else { return nil }
        let location = NSEvent.mouseLocation
        return CGPoint(x: location.x - union.minX, y: union.maxY - location.y)
    }

    func start(engine: EffectEngine) {
        guard globalMonitor == nil, localMonitor == nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak engine] _ in
            DispatchQueue.main.async {
                guard let point = Self.overlayPoint() else { return }
                engine?.trigger(at: point)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak engine] event in
            if let point = Self.overlayPoint() {
                engine?.trigger(at: point)
            }
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

}
