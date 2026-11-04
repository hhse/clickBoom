import SwiftUI
import Combine
import CoreGraphics
import ServiceManagement
import Carbon

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
    case firework
    case bolt

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
        case .firework: return "烟花"
        case .bolt: return "闪电"
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
        case .firework: return "fireworks"
        case .bolt: return "bolt.fill"
        }
    }

    /// 一句话说明，帮助用户在视觉网格里快速挑选
    var subtitle: String {
        switch self {
        case .spark: return "短线条四散"
        case .ripple: return "圆弧向外展开"
        case .burst: return "细光线快速划过"
        case .confetti: return "彩纸轻轻飘落"
        case .emoji: return "弹出随机表情"
        case .wave: return "三圈涟漪扩散"
        case .starflare: return "镜头星芒高光"
        case .pixel: return "8-bit 方块飞散"
        case .hearts: return "爱心错峰上浮"
        case .firework: return "拖尾焰火炸开"
        case .bolt: return "锯齿电弧闪现"
        }
    }
}

enum TrailStyle: String, CaseIterable, Identifiable {
    case classic
    case brush
    case neon
    case comet
    case ribbon
    case stardust

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return "光带"
        case .brush: return "毛笔"
        case .neon: return "霓虹"
        case .comet: return "彗星"
        case .ribbon: return "丝带"
        case .stardust: return "星尘"
        }
    }

    var icon: String {
        switch self {
        case .classic: return "scribble.variable"
        case .brush: return "paintbrush.pointed"
        case .neon: return "lightbulb.led"
        case .comet: return "sparkle"
        case .ribbon: return "wind"
        case .stardust: return "sparkles"
        }
    }

    var subtitle: String {
        switch self {
        case .classic: return "柔和渐隐的光带"
        case .brush: return "随快慢变粗细的笔锋"
        case .neon: return "高亮的霓虹灯管"
        case .comet: return "拖着星火的彗星"
        case .ribbon: return "半透明的宽丝带"
        case .stardust: return "散落的星尘光点"
        }
    }
}

enum EffectPreset: String, CaseIterable, Identifiable {
    case standard
    case blue
    case ring
    case confetti
    case cyber
    case fireworks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "默认"
        case .blue: return "蓝光"
        case .ring: return "圆环"
        case .confetti: return "彩纸"
        case .cyber: return "赛博"
        case .fireworks: return "烟花"
        }
    }

    var icon: String {
        switch self {
        case .standard: return "sparkles"
        case .blue: return "circle.fill"
        case .ring: return "circle.dotted"
        case .confetti: return "square.grid.2x2"
        case .cyber: return "bolt.fill"
        case .fireworks: return "fireworks"
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
        case .cyber:
            return Settings(effect: .bolt, color: "#5BE7FF", count: 6, size: 6, radius: 34, durationMs: 420, scale: 1.0)
        case .fireworks:
            return Settings(effect: .firework, color: "#FFB45E", count: 11, size: 5, radius: 46, durationMs: 760, scale: 1.0)
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

// MARK: - 自定义预设
/// 用户保存的一整套外观参数，Codable 后直接存进 UserDefaults。
struct PresetSnapshot: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var effect: String
    var colorHex: String
    var count: Int
    var size: Double
    var radius: Double
    var durationMs: Double
    var scale: Double
    var emoji: String
    // 拖尾参数是 1.1.8 才加入的：全部可选，旧预设解码时缺字段也不会失败。
    var trailEnabled: Bool? = nil
    var trailStyle: String? = nil
    var trailColorHex: String? = nil
    var trailFollowsColor: Bool? = nil
    var trailWidth: Double? = nil
    var trailOpacity: Double? = nil
    var trailLifetimeMs: Double? = nil
}

// MARK: - 1. 全局状态管理 (AppState)
/// 设置统一用 @Published 保存，再手动写回 UserDefaults。
/// 这样面板、菜单栏和覆盖层读的是同一份状态，改完立刻同步，不会各显示各的。
class AppState: NSObject, ObservableObject {
    static let shared = AppState()

    private enum Key {
        static let isEnabled = "isEnabled"
        static let effectColorHex = "sparkColorHex"
        static let particleSize = "sparkSize"
        static let particleRadius = "sparkRadius"
        static let particleCount = "sparkCount"
        static let durationMs = "duration"
        static let scale = "extraScale"
        static let effectStyleRaw = "effectStyle"
        static let randomEffectEnabled = "randomEffectEnabled"
        static let trailEnabled = "trailEnabled"
        static let trailStyleRaw = "trailStyle"
        static let trailColorHex = "trailColorHex"
        static let trailFollowsColor = "trailFollowsColor"
        static let trailWidth = "trailWidth"
        static let trailOpacity = "trailOpacity"
        static let trailLifetimeMs = "trailLifetime"
        static let comboBoostEnabled = "comboBoostEnabled"
        static let customEmoji = "customEmoji"
        static let rightClickEnabled = "rightClickEnabled"
        static let hotkeyEnabled = "hotkeyEnabled"
        static let savedPresets = "savedPresets"
    }

    private let defaults = UserDefaults.standard

    @Published var isEnabled: Bool = true {
        didSet { defaults.set(isEnabled, forKey: Key.isEnabled) }
    }
    @Published var effectColorHex: String = "#FFFFFF" {
        didSet { defaults.set(effectColorHex, forKey: Key.effectColorHex) }
    }
    @Published var particleSize: Double = 10.0 {
        didSet { defaults.set(particleSize, forKey: Key.particleSize) }
    }
    @Published var particleRadius: Double = 15.0 {
        didSet { defaults.set(particleRadius, forKey: Key.particleRadius) }
    }
    @Published var particleCount: Int = 8 {
        didSet { defaults.set(particleCount, forKey: Key.particleCount) }
    }
    @Published var durationMs: Double = 400.0 {
        didSet { defaults.set(durationMs, forKey: Key.durationMs) }
    }
    @Published var scale: Double = 1.0 {
        didSet { defaults.set(scale, forKey: Key.scale) }
    }
    @Published var effectStyleRaw: String = EffectStyle.spark.rawValue {
        didSet { defaults.set(effectStyleRaw, forKey: Key.effectStyleRaw) }
    }
    @Published var randomEffectEnabled: Bool = false {
        didSet { defaults.set(randomEffectEnabled, forKey: Key.randomEffectEnabled) }
    }
    /// 拖尾是独立开关：打开后无论选哪种点击效果，移动鼠标都会留下光带
    @Published var trailEnabled: Bool = false {
        didSet { defaults.set(trailEnabled, forKey: Key.trailEnabled) }
    }
    /// 拖尾样式：光带 / 毛笔 / 霓虹 / 彗星 / 丝带 / 星尘
    @Published var trailStyleRaw: String = TrailStyle.classic.rawValue {
        didSet { defaults.set(trailStyleRaw, forKey: Key.trailStyleRaw) }
    }
    @Published var trailColorHex: String = "#FFFFFF" {
        didSet { defaults.set(trailColorHex, forKey: Key.trailColorHex) }
    }
    /// 默认跟随点击效果的颜色，关掉后使用拖尾自己的颜色
    @Published var trailFollowsColor: Bool = true {
        didSet { defaults.set(trailFollowsColor, forKey: Key.trailFollowsColor) }
    }
    /// 拖尾基准宽度（点）；实际绘制时再乘样式系数和全局缩放
    @Published var trailWidth: Double = 10.0 {
        didSet { defaults.set(trailWidth, forKey: Key.trailWidth) }
    }
    @Published var trailOpacity: Double = 1.0 {
        didSet { defaults.set(trailOpacity, forKey: Key.trailOpacity) }
    }
    /// 拖尾停留时长（毫秒），与点击效果的 durationMs 解耦
    @Published var trailLifetimeMs: Double = 400.0 {
        didSet { defaults.set(trailLifetimeMs, forKey: Key.trailLifetimeMs) }
    }
    @Published var comboBoostEnabled: Bool = false {
        didSet { defaults.set(comboBoostEnabled, forKey: Key.comboBoostEnabled) }
    }
    @Published var customEmoji: String = "✨" {
        didSet { defaults.set(customEmoji, forKey: Key.customEmoji) }
    }
    @Published var rightClickEnabled: Bool = true {
        didSet { defaults.set(rightClickEnabled, forKey: Key.rightClickEnabled) }
    }
    @Published var hotkeyEnabled: Bool = true {
        didSet { defaults.set(hotkeyEnabled, forKey: Key.hotkeyEnabled) }
    }
    @Published var savedPresets: [PresetSnapshot] = [] {
        didSet {
            guard let data = try? JSONEncoder().encode(savedPresets) else { return }
            defaults.set(data, forKey: Key.savedPresets)
        }
    }

    @Published var comboCount: Int = 0

    /// 暂停状态的剩余时间；由暂停计时器刷新，用来驱动菜单栏和面板上的倒计时
    @Published private(set) var pauseUntil: Date?
    @Published private(set) var pauseRemaining: TimeInterval = 0
    private var pauseTimer: Timer?

    override init() {
        super.init()

        let d = UserDefaults.standard

        if let value = d.object(forKey: Key.isEnabled) as? Bool { isEnabled = value }
        if let value = d.string(forKey: Key.effectColorHex) { effectColorHex = value }
        if let value = d.object(forKey: Key.particleSize) as? NSNumber { particleSize = value.doubleValue }
        if let value = d.object(forKey: Key.particleRadius) as? NSNumber { particleRadius = value.doubleValue }
        if let value = d.object(forKey: Key.particleCount) as? NSNumber { particleCount = value.intValue }
        if let value = d.object(forKey: Key.durationMs) as? NSNumber { durationMs = value.doubleValue }
        if let value = d.object(forKey: Key.scale) as? NSNumber { scale = value.doubleValue }
        if let value = d.string(forKey: Key.effectStyleRaw),
           EffectStyle(rawValue: value) != nil {
            effectStyleRaw = value
        }
        if let value = d.object(forKey: Key.randomEffectEnabled) as? Bool { randomEffectEnabled = value }
        if let value = d.object(forKey: Key.trailEnabled) as? Bool { trailEnabled = value }
        if let value = d.string(forKey: Key.trailStyleRaw),
           TrailStyle(rawValue: value) != nil {
            trailStyleRaw = value
        }
        if let value = d.string(forKey: Key.trailColorHex) { trailColorHex = value }
        if let value = d.object(forKey: Key.trailFollowsColor) as? Bool { trailFollowsColor = value }
        if let value = d.object(forKey: Key.trailWidth) as? NSNumber { trailWidth = value.doubleValue }
        if let value = d.object(forKey: Key.trailOpacity) as? NSNumber { trailOpacity = value.doubleValue }
        if let value = d.object(forKey: Key.trailLifetimeMs) as? NSNumber { trailLifetimeMs = value.doubleValue }
        if let value = d.object(forKey: Key.comboBoostEnabled) as? Bool { comboBoostEnabled = value }
        if let value = d.string(forKey: Key.customEmoji) { customEmoji = value }
        if let value = d.object(forKey: Key.rightClickEnabled) as? Bool { rightClickEnabled = value }
        if let value = d.object(forKey: Key.hotkeyEnabled) as? Bool { hotkeyEnabled = value }
        if let data = d.data(forKey: Key.savedPresets),
           let decoded = try? JSONDecoder().decode([PresetSnapshot].self, from: data) {
            savedPresets = decoded
        }
    }

    var effectStyle: Binding<EffectStyle> {
        Binding(
            get: { EffectStyle(rawValue: self.effectStyleRaw) ?? .spark },
            set: { self.effectStyleRaw = $0.rawValue }
        )
    }

    var trailStyle: Binding<TrailStyle> {
        Binding(
            get: { TrailStyle(rawValue: self.trailStyleRaw) ?? .classic },
            set: { self.trailStyleRaw = $0.rawValue }
        )
    }

    var trailColor: Color {
        let hex = trailFollowsColor ? effectColorHex : trailColorHex
        return Color(hex: hex) ?? .white
    }

    var trailColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: self.trailColorHex) ?? .white },
            set: { self.trailColorHex = $0.toHex() ?? "#FFFFFF" }
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

    var isPaused: Bool {
        guard let pauseUntil else { return false }
        return pauseUntil > Date()
    }

    /// 暂停剩余时间的人类可读描述，面板和菜单栏共用
    var pauseRemainingText: String {
        let seconds = Int(max(0, pauseRemaining).rounded(.up))
        if seconds >= 60 {
            let minutes = Int((Double(seconds) / 60.0).rounded(.up))
            return "约 \(minutes) 分钟后恢复"
        }
        return "约 \(max(1, seconds)) 秒后恢复"
    }

    func toggleEnabled() {
        // 暂停期间按快捷键视为「立刻恢复」，避免图标和实际状态互相打架
        if isPaused {
            resume()
            isEnabled = true
            return
        }
        isEnabled.toggle()
    }

    func pause(minutes: Int) {
        let seconds = TimeInterval(max(1, minutes) * 60)
        pauseUntil = Date().addingTimeInterval(seconds)
        pauseRemaining = seconds
        startPauseTimer()
    }

    func resume() {
        pauseUntil = nil
        pauseRemaining = 0
        pauseTimer?.invalidate()
        pauseTimer = nil
    }

    private func startPauseTimer() {
        pauseTimer?.invalidate()
        let timer = Timer(
            timeInterval: 15,
            target: self,
            selector: #selector(pauseTick),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        pauseTimer = timer
    }

    @objc private func pauseTick() {
        guard let pauseUntil else {
            resume()
            return
        }
        let remaining = pauseUntil.timeIntervalSinceNow
        if remaining <= 0 {
            resume()
        } else {
            pauseRemaining = remaining
        }
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

    func apply(_ preset: PresetSnapshot) {
        if EffectStyle(rawValue: preset.effect) != nil {
            effectStyleRaw = preset.effect
        }
        effectColorHex = preset.colorHex
        particleCount = preset.count
        particleSize = preset.size
        particleRadius = preset.radius
        durationMs = preset.durationMs
        scale = preset.scale
        customEmoji = preset.emoji
        if let enabled = preset.trailEnabled { trailEnabled = enabled }
        if let style = preset.trailStyle, TrailStyle(rawValue: style) != nil { trailStyleRaw = style }
        if let color = preset.trailColorHex { trailColorHex = color }
        if let follows = preset.trailFollowsColor { trailFollowsColor = follows }
        if let width = preset.trailWidth { trailWidth = width }
        if let opacity = preset.trailOpacity { trailOpacity = opacity }
        if let lifetime = preset.trailLifetimeMs { trailLifetimeMs = lifetime }
        randomEffectEnabled = false
        comboCount = 0
    }

    @discardableResult
    func saveCurrentPreset(named rawName: String) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = name.isEmpty ? "我的预设 \(savedPresets.count + 1)" : name
        let snapshot = PresetSnapshot(
            name: finalName,
            effect: effectStyleRaw,
            colorHex: effectColorHex,
            count: particleCount,
            size: particleSize,
            radius: particleRadius,
            durationMs: durationMs,
            scale: scale,
            emoji: customEmoji,
            trailEnabled: trailEnabled,
            trailStyle: trailStyleRaw,
            trailColorHex: trailColorHex,
            trailFollowsColor: trailFollowsColor,
            trailWidth: trailWidth,
            trailOpacity: trailOpacity,
            trailLifetimeMs: trailLifetimeMs
        )
        if let index = savedPresets.firstIndex(where: { $0.name == finalName }) {
            savedPresets[index] = snapshot
        } else {
            savedPresets.append(snapshot)
        }
        return finalName
    }

    func deletePreset(_ preset: PresetSnapshot) {
        savedPresets.removeAll { $0.id == preset.id }
    }

    /// 恢复默认值：只重置效果参数和选项，不动「启用」开关和已保存的预设。
    func resetToDefaults() {
        effectColorHex = "#FFFFFF"
        particleSize = 10
        particleRadius = 15
        particleCount = 8
        durationMs = 400
        scale = 1.0
        effectStyleRaw = EffectStyle.spark.rawValue
        randomEffectEnabled = false
        trailEnabled = false
        trailStyleRaw = TrailStyle.classic.rawValue
        trailColorHex = "#FFFFFF"
        trailFollowsColor = true
        trailWidth = 10
        trailOpacity = 1.0
        trailLifetimeMs = 400
        comboBoostEnabled = false
        customEmoji = "✨"
        rightClickEnabled = true
        comboCount = 0
    }
}

// MARK: - 全局快捷键
/// Carbon 的 RegisterEventHotKey 不需要额外权限，用来给「开关特效」绑一个全局快捷键。
@MainActor
final class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    static let shortcutLabel = "⌃⌥B"

    @Published private(set) var isRegistered = false

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func sync() {
        unregister()
        guard AppState.shared.hotkeyEnabled else { return }
        installHandlerIfNeeded()

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C_4B42), id: 1)
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_B),
            UInt32(controlKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRef = ref
            isRegistered = true
        } else {
            isRegistered = false
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
        isRegistered = false
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            clickBoomHotKeyHandler,
            1,
            &eventType,
            nil,
            &handlerRef
        )
    }
}

nonisolated private func clickBoomHotKeyHandler(
    _ callRef: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    Task { @MainActor in
        AppState.shared.toggleEnabled()
    }
    return noErr
}

// MARK: - 应用信息
enum AppInfo {
    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.10"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "12"
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

    /// 菜单栏小红点用；随 status 的 @Published 一起刷新
    var hasUpdate: Bool {
        if case .available = status { return true }
        return false
    }

    private let latestURL = URL(string: "https://api.github.com/repos/hhse/clickBoom/releases/latest")!
    private let lastCheckKey = "lastUpdateCheckAt"

    /// 启动时调用：距上次检查超过 interval 才真正请求，避免每次打开都打 GitHub。
    func checkIfDue(interval: TimeInterval = 24 * 60 * 60) {
        let last = UserDefaults.standard.double(forKey: lastCheckKey)
        let now = Date().timeIntervalSince1970
        guard last <= 0 || now - last >= interval else { return }
        UserDefaults.standard.set(now, forKey: lastCheckKey)
        check()
    }

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

// MARK: - 系统无障碍设置
/// 跟随「减弱动态效果」：打开时把旋转、摇摆这类大幅位移收起来，动画更克制。
@MainActor
final class AccessibilitySettings: ObservableObject {
    static let shared = AccessibilitySettings()

    @Published private(set) var reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    private init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                AccessibilitySettings.shared.refresh()
            }
        }
    }

    func refresh() {
        reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
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
        .defaultSize(width: 440, height: 820)
        // 常驻菜单栏的工具不该在每次启动（尤其是开机自启）时弹一个面板出来。
        // 首次启动仍会由 AppDelegate 主动打开一次，之后从菜单栏或 Dock 图标进入。
        .defaultLaunchBehavior(.suppressed)
        // 同时关掉窗口状态恢复：否则「退出时面板还开着」会让下次启动（含登录启动）又被系统带出来。
        .restorationBehavior(.disabled)

        MenuBarExtra {
            MenuBarQuickPanel()
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - 从 AppDelegate 打开控制面板
/// SwiftUI 的 openWindow 只能在视图里取到，这里借菜单栏图标把它捕获下来，
/// 好让「点 Dock 图标」「首次启动」这类 AppDelegate 场景也能打开面板。
@MainActor
final class PanelPresenter {
    static let shared = PanelPresenter()

    private var openAction: ((String) -> Void)?

    func bind(_ action: @escaping (String) -> Void) {
        openAction = action
    }

    /// 面板动作还没绑定时（启动瞬间）自动重试几次。
    func show(retries: Int = 8) {
        if let openAction {
            openAction("control-panel")
            return
        }
        guard retries > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.show(retries: retries - 1)
        }
    }
}

/// 菜单栏图标：反映开关状态，并在出现时把 openWindow 交给 PanelPresenter。
struct MenuBarLabel: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject private var appState = AppState.shared
    @ObservedObject private var update = UpdateChecker.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: appState.isPaused ? "pause.circle" : "sparkles")
                // 关闭时把图标调暗，一眼能看出当前没生效
                .opacity(appState.isEnabled ? 1 : 0.35)
                .accessibilityLabel(Text(appState.isEnabled ? "ClickBoom，已开启" : "ClickBoom，已关闭"))

            if update.hasUpdate {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 5, height: 5)
                    .offset(x: 3, y: -2)
            }
        }
        .onAppear {
            PanelPresenter.shared.bind { id in
                openWindow(id: id)
            }
        }
    }
}

// MARK: - 菜单栏快速控制面板
struct MenuBarQuickPanel: View {
    @Environment(\.openWindow) private var openWindow
    @StateObject private var appState = AppState.shared
    @StateObject private var loginItem = LaunchAtLogin.shared
    @StateObject private var permission = InputPermission.shared
    @StateObject private var update = UpdateChecker.shared
    @StateObject private var hotkey = HotKeyManager.shared

    private var particleCount: Binding<Double> {
        Binding(
            get: { Double(appState.particleCount) },
            set: { appState.particleCount = Int($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: appState.isPaused ? "pause.circle.fill" : "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(appState.isPaused ? Color.orange : Color.accentColor)
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

            if appState.isPaused {
                HStack(spacing: 8) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(.orange)
                    Text("已暂停，\(appState.pauseRemainingText)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("恢复") { appState.resume() }
                        .buttonStyle(.link)
                        .font(.system(size: 11))
                }
            }

            Divider()

            HStack(spacing: 8) {
                Button {
                    if let point = OverlayGeometry.mousePoint() {
                        EffectEngine.shared.preview(at: point)
                    }
                } label: {
                    Label("预览", systemImage: "play.circle")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Menu {
                    Button("暂停 15 分钟") { appState.pause(minutes: 15) }
                    Button("暂停 30 分钟") { appState.pause(minutes: 30) }
                    Button("暂停 60 分钟") { appState.pause(minutes: 60) }
                    if appState.isPaused {
                        Divider()
                        Button("立即恢复") { appState.resume() }
                    }
                } label: {
                    Label("暂停", systemImage: "pause.circle")
                        .font(.system(size: 11, weight: .medium))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Spacer()
            }

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

            if !appState.savedPresets.isEmpty {
                Menu {
                    ForEach(appState.savedPresets) { preset in
                        Button {
                            appState.apply(preset)
                        } label: {
                            Text(preset.name)
                        }
                    }
                } label: {
                    Label("我的预设", systemImage: "bookmark.fill")
                }
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
            Toggle("滑动拖尾", isOn: $appState.trailEnabled)
            if appState.trailEnabled {
                Picker("拖尾样式", selection: $appState.trailStyleRaw) {
                    ForEach(TrailStyle.allCases) { style in
                        Text(style.title).tag(style.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            Toggle("连续点击放大", isOn: $appState.comboBoostEnabled)
            if appState.comboBoostEnabled, appState.comboCount > 1 {
                Label("连击 ×\(appState.comboCount)", systemImage: "flame.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            Toggle("全局快捷键 \(HotKeyManager.shortcutLabel)", isOn: Binding(
                get: { appState.hotkeyEnabled },
                set: { newValue in
                    appState.hotkeyEnabled = newValue
                    HotKeyManager.shared.sync()
                }
            ))
            if appState.hotkeyEnabled, !hotkey.isRegistered {
                Text("快捷键没注册上，可能被其他 App 占用了。")
                    .font(.system(size: 10))
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
struct ControlPanelView: View {
    @StateObject var appState = AppState.shared
    @StateObject private var loginItem = LaunchAtLogin.shared
    @StateObject private var permission = InputPermission.shared
    @StateObject private var update = UpdateChecker.shared
    @StateObject private var hotkey = HotKeyManager.shared
    @State private var showResetConfirm = false
    @State private var showSavePreset = false
    @State private var presetName = ""

    private let quickColors = ["#FFFFFF", "#66E8FF", "#63F2CE", "#FF77C8", "#FFB45E", "#B48CFF"]
    private let quickEmojis = ["✨", "🔥", "💖", "🎉", "⚡", "💫", "🌸", "🫧"]

    /// Emoji 快选：点一下加入，再点一下移除
    private func toggleEmoji(_ emoji: String) {
        if appState.customEmoji.contains(emoji) {
            appState.customEmoji = appState.customEmoji.replacingOccurrences(of: emoji, with: "")
        } else {
            appState.customEmoji += emoji
        }
        if appState.customEmoji.isEmpty {
            appState.customEmoji = "✨"
        }
    }

    /// 在鼠标当前位置放一次效果，方便调参时立即看到结果
    private func previewEffect() {
        guard let point = OverlayGeometry.mousePoint() else { return }
        EffectEngine.shared.preview(at: point)
    }

    private func previewTrail() {
        guard let point = OverlayGeometry.mousePoint() else { return }
        EffectEngine.shared.previewTrailOnly(at: point)
    }
    
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

                    Button {
                        previewEffect()
                    } label: {
                        Label("预览", systemImage: "play.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.white)
                    .help("在当前鼠标位置试一下当前效果")

                    Menu {
                        Button("暂停 15 分钟") { appState.pause(minutes: 15) }
                        Button("暂停 30 分钟") { appState.pause(minutes: 30) }
                        Button("暂停 60 分钟") { appState.pause(minutes: 60) }
                        if appState.isPaused {
                            Divider()
                            Button("立即恢复") { appState.resume() }
                        }
                    } label: {
                        Image(systemName: "pause.circle")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .tint(.white)
                    .help("定时暂停特效")

                    // 顶部开关
                    Toggle("", isOn: $appState.isEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        .scaleEffect(0.8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

                if appState.isPaused {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.orange)
                        Text("特效已暂停，\(appState.pauseRemainingText)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Button("恢复") { appState.resume() }
                            .buttonStyle(.link)
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
                
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

                            HStack(spacing: 8) {
                                ForEach(quickColors, id: \.self) { hex in
                                    Button {
                                        appState.effectColorHex = hex
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: hex) ?? .white)
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                Circle().stroke(
                                                    Color.white.opacity(appState.effectColorHex.uppercased() == hex ? 0.95 : 0.15),
                                                    lineWidth: appState.effectColorHex.uppercased() == hex ? 2 : 1
                                                )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .help(hex)
                                }
                                Spacer(minLength: 0)
                            }

                            Divider().background(Color.white.opacity(0.1))

                            Text("效果样式")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                                ForEach(EffectStyle.allCases) { effect in
                                    EffectChip(effect: effect, isSelected: appState.effectStyle.wrappedValue == effect) {
                                        appState.effectStyleRaw = effect.rawValue
                                    }
                                }
                            }

                            if appState.effectStyle.wrappedValue == .emoji {
                                Divider().background(Color.white.opacity(0.1))

                                HStack(spacing: 10) {
                                    Label("自定义 Emoji", systemImage: "face.smiling")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    TextField("例如：✨🔥💖", text: $appState.customEmoji)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 130)
                                }

                                HStack(spacing: 6) {
                                    ForEach(quickEmojis, id: \.self) { emoji in
                                        Button {
                                            toggleEmoji(emoji)
                                        } label: {
                                            Text(emoji)
                                                .font(.system(size: 14))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 4)
                                                .background(Color.white.opacity(appState.customEmoji.contains(emoji) ? 0.22 : 0.06))
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                        .help("点一下加入 / 移除")
                                    }
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

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Text("我的预设")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white.opacity(0.45))
                                Spacer()
                                Button {
                                    presetName = ""
                                    showSavePreset = true
                                } label: {
                                    Label("保存当前", systemImage: "plus")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            if appState.savedPresets.isEmpty {
                                Text("调好参数后点「保存当前」，就能把自己的搭配固定下来。")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(appState.savedPresets) { preset in
                                        SavedPresetChip(preset: preset) {
                                            appState.apply(preset)
                                        } onDelete: {
                                            appState.deletePreset(preset)
                                        }
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

                        SectionCard(icon: "scribble.variable", title: "拖尾") {
                            HStack(spacing: 8) {
                                Spacer(minLength: 0)
                                Text("滑动拖尾")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                Toggle("", isOn: $appState.trailEnabled)
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .tint(.teal)
                                Spacer(minLength: 0)
                            }
                            Text("移动鼠标时留下渐隐光带，可与任意点击效果同时开启")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)

                            if appState.trailEnabled {
                                HStack {
                                    Text("拖尾样式")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Button {
                                        previewTrail()
                                    } label: {
                                        Label("预览", systemImage: "play.circle")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.teal)
                                    .help("在当前鼠标位置播放一段拖尾")
                                }

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(TrailStyle.allCases) { style in
                                        Button {
                                            withAnimation(.easeOut(duration: 0.12)) {
                                                appState.trailStyleRaw = style.rawValue
                                            }
                                        } label: {
                                            HStack(spacing: 5) {
                                                Image(systemName: style.icon)
                                                    .font(.system(size: 11, weight: .semibold))
                                                Text(style.title)
                                                    .font(.system(size: 11, weight: .medium))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 7)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .fill(appState.trailStyleRaw == style.rawValue ? Color.teal.opacity(0.26) : Color.white.opacity(0.06))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(appState.trailStyleRaw == style.rawValue ? Color.teal.opacity(0.65) : Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                            .foregroundColor(appState.trailStyleRaw == style.rawValue ? .white : .white.opacity(0.65))
                                        }
                                        .buttonStyle(.plain)
                                        .help(style.subtitle)
                                    }
                                }

                                Divider().background(Color.white.opacity(0.1))

                                Toggle("跟随点击颜色", isOn: $appState.trailFollowsColor)
                                    .toggleStyle(.switch)
                                    .tint(.teal)
                                Text("关闭后可给拖尾单独选颜色")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.45))

                                if !appState.trailFollowsColor {
                                    HStack {
                                        Text("拖尾颜色")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Spacer()
                                        ColorPicker("", selection: appState.trailColorBinding)
                                            .labelsHidden()
                                    }
                                }

                                ModernSlider(label: "粗细", value: $appState.trailWidth, range: 2...30, icon: "lineweight", format: "%.0f")
                                ModernSlider(label: "透明度", value: Binding(get: { appState.trailOpacity * 100 }, set: { appState.trailOpacity = $0 / 100 }), range: 20...100, icon: "circle.lefthalf.filled", format: "%.0f%%")
                                ModernSlider(label: "停留", value: $appState.trailLifetimeMs, range: 200...2000, icon: "hourglass", format: "%.0f 毫秒")
                            }
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

                            Divider().background(Color.white.opacity(0.1))

                            Toggle("右键 / 中键也触发", isOn: $appState.rightClickEnabled)
                                .toggleStyle(.switch)
                                .tint(.purple)
                            Text("右键菜单、中键点击同样弹出效果")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))

                            Divider().background(Color.white.opacity(0.1))

                            Toggle("全局快捷键 \(HotKeyManager.shortcutLabel)", isOn: Binding(
                                get: { appState.hotkeyEnabled },
                                set: { newValue in
                                    appState.hotkeyEnabled = newValue
                                    HotKeyManager.shared.sync()
                                }
                            ))
                            .toggleStyle(.switch)
                            .tint(.mint)
                            Text("在任意 App 里按 \(HotKeyManager.shortcutLabel) 开关特效，不需要额外权限")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))
                            if appState.hotkeyEnabled, !hotkey.isRegistered {
                                Label("注册失败，可能被其他 App 占用了", systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            }

                            Divider().background(Color.white.opacity(0.1))

                            Button(role: .destructive) {
                                showResetConfirm = true
                            } label: {
                                Label("恢复默认设置", systemImage: "arrow.counterclockwise")
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
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
        .confirmationDialog("恢复默认设置？", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("恢复默认", role: .destructive) { appState.resetToDefaults() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("颜色、粒子、动画参数和选项都会回到初始值。")
        }
        .alert("保存为预设", isPresented: $showSavePreset) {
            TextField("预设名称", text: $presetName)
            Button("保存") {
                appState.saveCurrentPreset(named: presetName)
                presetName = ""
            }
            Button("取消", role: .cancel) { presetName = "" }
        } message: {
            Text("会保存当前效果、颜色、粒子、动画和 Emoji；同名预设直接覆盖。")
        }
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

struct EffectChip: View {
    let effect: EffectStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: effect.icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(effect.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .foregroundColor(isSelected ? .black : .white.opacity(0.8))
            .background(isSelected ? Color.white : Color.white.opacity(0.07))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help(effect.subtitle)
    }
}

struct SavedPresetChip: View {
    let preset: PresetSnapshot
    let onApply: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onApply) {
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10))
                    Text(preset.name)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("删除预设")
        }
        .foregroundColor(.white.opacity(0.85))
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.07))
        .cornerRadius(8)
        .contextMenu {
            Button("删除预设", role: .destructive, action: onDelete)
        }
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
            .frame(maxWidth: .infinity, alignment: .center)
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
        // 直接读 cgColor.components 有坑：目录色（如 .red）、灰度色只有 2 个分量，
        // 广色域色还会超出 0...1，取不到就会让颜色被静默重置成白色。
        // 统一转换到 sRGB 再钳制到合法区间。
        guard let srgb = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        func channel(_ value: CGFloat) -> Int {
            Int((min(max(value, 0), 1) * 255).rounded())
        }
        return String(
            format: "#%02X%02X%02X",
            channel(srgb.redComponent),
            channel(srgb.greenComponent),
            channel(srgb.blueComponent)
        )
    }
}

// MARK: - 6. 核心逻辑 (保持不变)
/// 全局坐标 → 覆盖层坐标的换算，面板预览和全局监听共用。
enum OverlayGeometry {
    /// 全局坐标（左下原点）→ 覆盖层视图坐标（左上原点，覆盖全部屏幕）
    static func mousePoint() -> CGPoint? {
        let union = ScreenUnion.frame
        guard union.height > 0 else { return nil }
        let location = NSEvent.mouseLocation
        return CGPoint(x: location.x - union.minX, y: union.maxY - location.y)
    }
}

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
    private static let hasLaunchedOnceKey = "hasLaunchedOnce"

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
        openPanelOnFirstLaunchIfNeeded()
        HotKeyManager.shared.sync()
        UpdateChecker.shared.checkIfDue()
    }

    /// 第一次安装后主动亮一次面板，免得用户以为没打开；之后启动只留在菜单栏。
    private func openPanelOnFirstLaunchIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.hasLaunchedOnceKey) else { return }
        defaults.set(true, forKey: Self.hasLaunchedOnceKey)
        PanelPresenter.shared.show(retries: 6)
    }

    /// 点 Dock 图标时，如果面板已经被关掉，就重新打开（SwiftUI 的 Window 场景不会自愈）。
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 不能用 flag：特效覆盖层窗口一直「可见」，它会让这个值恒为 true。
        let hasPanel = NSApp.windows.contains { $0.isVisible && $0.level == .normal && $0.canBecomeMain }
        if !hasPanel {
            PanelPresenter.shared.show()
        }
        return true
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

/// 滑动拖尾上的一个采样点，时间用来做「越旧越淡」的衰减。
struct TrailPoint {
    var x, y: Double
    var time: Date
}

class EffectEngine: ObservableObject {
    /// 面板里的「预览」和覆盖层共用同一个引擎
    static let shared = EffectEngine()

    /// 全屏连点时的粒子总量上限，超过就丢掉最旧的一批，避免绘制开销拖垮帧率。
    private static let maxParticles = 600

    /// 拖尾的采样点上限：即便拉得很长也只保留最后一小段
    private static let maxTrailPoints = 180

    @Published var particles: [Particle] = []
    /// 滑动拖尾的轨迹点，按时间从旧到新排列
    @Published private(set) var trailPoints: [TrailPoint] = []

    private var lastClickTime = Date.distantPast
    private var comboLevel = 0
    private var lastTrailSampleTime = Date.distantPast
    /// 预览动画用：每次重新预览时自增，旧的一批定时投递就会自动作废
    private var previewToken = 0

    /// 拖尾在屏幕上停留多久：由拖尾自己的「停留时长」决定，与点击效果解耦
    var trailLifetime: TimeInterval {
        min(2.5, max(0.15, AppState.shared.trailLifetimeMs / 1000.0))
    }

    func trigger(at point: CGPoint, force: Bool = false) {
        let state = AppState.shared
        guard force || (state.isEnabled && !state.isPaused) else { return }

        let effect = state.randomEffectEnabled
            ? (EffectStyle.allCases.randomElement() ?? .spark)
            : state.effectStyle.wrappedValue

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
        let overflow = max(0, particles.count + newParticles.count - Self.maxParticles)
        if overflow > 0 {
            particles.removeFirst(min(overflow, particles.count))
        }
        particles.append(contentsOf: newParticles)

        // 点击时顺手补一个拖尾光点：先画光带再点也没关系，两者互不抢占
        if state.trailEnabled && !force {
            beginTrail(at: point)
        }
    }

    // MARK: 滑动拖尾

    /// 按下鼠标时补一个光点：只点击不移动也能看到反馈，同时结束正在播放的预览动画。
    func beginTrail(at point: CGPoint) {
        let state = AppState.shared
        guard state.trailEnabled, state.isEnabled, !state.isPaused else { return }
        previewToken &+= 1

        let now = Date()
        if let last = trailPoints.last,
           now.timeIntervalSince(last.time) < 0.3,
           hypot(last.x - point.x, last.y - point.y) < 60 {
            // 离上一笔很近，接着画，避免在轨迹中间断开
        } else {
            trailPoints.removeAll(keepingCapacity: true)
        }
        appendTrailPoint(point, at: now)
        lastTrailSampleTime = now
    }

    /// 鼠标移动（滑动或拖动）时持续记录轨迹点；只要打开拖尾开关就生效
    func extendTrail(at point: CGPoint) {
        let state = AppState.shared
        guard state.trailEnabled, state.isEnabled, !state.isPaused else { return }
        previewToken &+= 1

        let now = Date()
        // 高回报率鼠标一秒能发几百个事件，按 110Hz 采样已经足够顺滑
        guard now.timeIntervalSince(lastTrailSampleTime) >= 1.0 / 110.0 else { return }
        if let last = trailPoints.last {
            let dx = last.x - point.x
            let dy = last.y - point.y
            if dx * dx + dy * dy < 4 { return }
        }
        lastTrailSampleTime = now
        appendTrailPoint(point, at: now)
    }

    private func appendTrailPoint(_ point: CGPoint, at time: Date) {
        trailPoints.append(TrailPoint(x: point.x, y: point.y, time: time))
        if trailPoints.count > Self.maxTrailPoints {
            trailPoints.removeFirst(trailPoints.count - Self.maxTrailPoints)
        }
    }

    /// 面板和菜单栏的「预览」：点击效果照常播放；开了拖尾就额外模拟一段滑动。
    func preview(at point: CGPoint) {
        if AppState.shared.trailEnabled {
            previewTrail(at: point)
        }
        trigger(at: point, force: true)
    }

    /// 只播放拖尾动画，不触发点击效果：面板里的「预览拖尾」按钮用
    func previewTrailOnly(at point: CGPoint) {
        guard AppState.shared.trailEnabled else { return }
        previewTrail(at: point)
    }

    private func previewTrail(at point: CGPoint) {
        previewToken &+= 1
        let token = previewToken
        trailPoints.removeAll(keepingCapacity: true)
        lastTrailSampleTime = .distantPast

        let state = AppState.shared
        let spread = max(40.0, state.particleRadius * state.scale * 3.2)
        let start = CGPoint(x: point.x - spread, y: point.y + spread * 0.35)
        let end = CGPoint(x: point.x + spread, y: point.y - spread * 0.35)
        let steps = 26

        for index in 0...steps {
            let t = Double(index) / Double(steps)
            let x = start.x + (end.x - start.x) * t
            let y = start.y + (end.y - start.y) * t + sin(t * .pi * 1.35) * spread * 0.6
            // 逐点投递，画出一条从左向右划过的弧线，而不是整条同时出现
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02 + Double(index) * 0.011) { [weak self] in
                guard let self, self.previewToken == token, AppState.shared.trailEnabled else { return }
                self.appendTrailPoint(CGPoint(x: x, y: y), at: Date())
            }
        }
    }

    func cleanUp(currentTime: Date) {
        let durationSec = AppState.shared.durationMs / 1000.0
        let alive = particles.filter { currentTime.timeIntervalSince($0.startTime) < durationSec }
        // 只有真的清理掉粒子时才重新赋值：否则每帧都会触发一次 @Published 更新。
        if alive.count != particles.count {
            particles = alive
        }

        let trailLife = trailLifetime
        let aliveTrail = trailPoints.filter { currentTime.timeIntervalSince($0.time) < trailLife }
        if aliveTrail.count != trailPoints.count {
            trailPoints = aliveTrail
        }
    }
}

struct EffectOverlayView: View {
    @ObservedObject var engine = EffectEngine.shared
    @StateObject private var mouseMonitor = GlobalMouseMonitor()
    @ObservedObject var appState = AppState.shared
    @ObservedObject private var permission = InputPermission.shared
    @ObservedObject private var accessibility = AccessibilitySettings.shared

    var body: some View {
        // 没有粒子也没有拖尾时暂停时间线，避免空闲状态一直 60fps 重绘（省电）
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: engine.particles.isEmpty && engine.trailPoints.isEmpty)) { context in
            Canvas { ctx, size in
                let now = context.date
                let durationSec = appState.durationMs / 1000.0
                let color = appState.effectColor.wrappedValue
                let sizeVal = appState.particleSize
                let radius = appState.particleRadius
                let scale = appState.scale

                // 拖尾先画，粒子叠在上面；透明度只作用于拖尾，不拖累点击效果
                ctx.opacity = appState.trailOpacity
                drawTrail(
                    now: now,
                    color: appState.trailColor,
                    size: appState.trailWidth,
                    scale: scale,
                    style: appState.trailStyle.wrappedValue,
                    context: ctx
                )
                ctx.opacity = 1

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
        .onAppear {
            mouseMonitor.start(engine: engine)
            syncTrailMotion()
        }
        .onDisappear { mouseMonitor.stop() }
        .onChange(of: appState.trailEnabled) { _, _ in syncTrailMotion() }
        .onChange(of: permission.isGranted) { _, granted in
            // 用户在「系统设置」里刚勾上输入监控时，启动阶段注册的监听往往收不到事件，
            // 重建一次监听即可让权限立刻生效，不必重启 App。
            if granted {
                mouseMonitor.restart(engine: engine)
                syncTrailMotion()
            }
        }
    }

    /// 拖尾开关打开时才监听鼠标移动，关闭时不额外占用事件通道
    private func syncTrailMotion() {
        mouseMonitor.syncTrailMotion(enabled: appState.trailEnabled, engine: engine)
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

    private func brushBlockHash(_ date: Date) -> Double {
        let block = Int(date.timeIntervalSinceReferenceDate * 30.0)
        return Double(((block &* 2654435761) >> 8) & 255) / 255.0
    }

    /// 左右两条边围成一条宽度可变的闭合色带，一次填充；避免逐段圆帽在笔身留下“串珠”
    private func brushRibbon(
        points: [TrailPoint],
        widths: [Double],
        widthScale: Double,
        offsetFactor: Double
    ) -> Path {
        var path = Path()
        let count = points.count
        for i in 0..<count {
            let p = points[i]
            let prev = points[max(0, i - 1)]
            let next = points[min(count - 1, i + 1)]
            let dx = next.x - prev.x
            let dy = next.y - prev.y
            let len = max(0.001, sqrt(dx * dx + dy * dy))
            let nx = -dy / len
            let ny = dx / len
            let offset = widths[i] * offsetFactor
            let half = widths[i] * widthScale * 0.5
            let wob = sin(p.x * 0.13 + p.y * 0.09) * 0.6
            let left = CGPoint(x: p.x + nx * (wob + offset + half), y: p.y + ny * (wob + offset + half))
            if i == 0 { path.move(to: left) } else { path.addLine(to: left) }
        }
        for i in (0..<count).reversed() {
            let p = points[i]
            let prev = points[max(0, i - 1)]
            let next = points[min(count - 1, i + 1)]
            let dx = next.x - prev.x
            let dy = next.y - prev.y
            let len = max(0.001, sqrt(dx * dx + dy * dy))
            let nx = -dy / len
            let ny = dx / len
            let offset = widths[i] * offsetFactor
            let half = widths[i] * widthScale * 0.5
            let wob = sin(p.x * 0.13 + p.y * 0.09) * 0.6
            path.addLine(to: CGPoint(x: p.x + nx * (wob + offset - half), y: p.y + ny * (wob + offset - half)))
        }
        path.closeSubpath()
        return path
    }

    /// 毛笔：整条轨迹一次填充成笔锋，宽度随速度变化，起笔与收笔自然收尖
    private func drawBrushStroke(
        now: Date,
        points: [TrailPoint],
        color: Color,
        baseWidth: Double,
        life: TimeInterval,
        context: GraphicsContext
    ) {
        guard !points.isEmpty else { return }

        if points.count == 1, let only = points.first {
            let freshness = max(0, 1 - now.timeIntervalSince(only.time) / life)
            let radius = max(1.2, baseWidth * 0.45 * (0.8 + 0.2 * freshness))
            var dot = Path()
            dot.addEllipse(in: CGRect(x: only.x - radius, y: only.y - radius, width: radius * 2, height: radius * 2))
            context.fill(dot, with: .color(color.opacity(0.8 * freshness)))
            return
        }

        let inkWidth = baseWidth * 1.7
        var widths = [Double](repeating: 0.4, count: points.count)
        for i in points.indices {
            let p = points[i]
            let freshness = max(0, 1 - now.timeIntervalSince(p.time) / life)
            var speed = 0.0
            if i > 0 {
                let prev = points[i - 1]
                let dt = max(0.001, p.time.timeIntervalSince(prev.time))
                let dx = p.x - prev.x
                let dy = p.y - prev.y
                speed = sqrt(dx * dx + dy * dy) / dt
            }
            let speedFactor = min(1.0, speed / 1300.0)
            let pressure = 1.5 - 1.0 * speedFactor
            let tailTaper = min(1.0, (Double(i) + 1) / 9.0)
            let wave = min(1.12, max(0.78,
                0.95 + 0.10 * sin(p.x * 0.11 + p.y * 0.07) + 0.06 * sin(p.x * 0.23 - p.y * 0.05)))
            let jitter = 0.92 + 0.16 * brushBlockHash(p.time)
            widths[i] = max(0.3, inkWidth * pressure * (0.45 + 0.55 * freshness) * tailTaper * wave * jitter)
        }

        // 墨晕
        context.fill(
            brushRibbon(points: points, widths: widths, widthScale: 1.55, offsetFactor: 0),
            with: .color(color.opacity(0.07))
        )
        // 笔身
        context.fill(
            brushRibbon(points: points, widths: widths, widthScale: 1.0, offsetFactor: 0),
            with: .color(color.opacity(0.85))
        )
        // 两侧毛锋：贴边一小条，让边缘不那么光滑
        for side in [-1.0, 1.0] {
            context.fill(
                brushRibbon(points: points, widths: widths, widthScale: 0.20, offsetFactor: 0.50 * side),
                with: .color(color.opacity(0.50))
            )
        }
        // 笔尖积墨，盖住色带末端的平口
        if let head = points.last {
            let freshness = max(0, 1 - now.timeIntervalSince(head.time) / life)
            let radius = max(1.2, widths[widths.count - 1] * 0.55)
            var dot = Path()
            dot.addEllipse(in: CGRect(x: head.x - radius, y: head.y - radius, width: radius * 2, height: radius * 2))
            context.fill(dot, with: .color(color.opacity(0.85 * freshness)))
        }
    }

    /// Catmull-Rom 平滑：只对拉得开的采样点做自适应细分，时间线性插值保证速度不变
    private func smoothedTrail(_ points: [TrailPoint]) -> [TrailPoint] {
        guard points.count > 2 else { return points }
        var result: [TrailPoint] = []
        result.reserveCapacity(points.count * 2)
        for index in 0..<(points.count - 1) {
            let p0 = points[max(0, index - 1)]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = points[min(points.count - 1, index + 2)]
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            let distance = sqrt(dx * dx + dy * dy)
            let steps = max(1, min(3, Int(ceil(distance / 10.0))))
            let span = p2.time.timeIntervalSince(p1.time)
            for step in 0..<steps {
                let t = Double(step) / Double(steps)
                result.append(TrailPoint(
                    x: catmullRom(p0.x, p1.x, p2.x, p3.x, t),
                    y: catmullRom(p0.y, p1.y, p2.y, p3.y, t),
                    time: p1.time.addingTimeInterval(span * t)
                ))
            }
        }
        if let last = points.last {
            result.append(last)
        }
        return result
    }

    private func catmullRom(_ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double, _ t: Double) -> Double {
        let t2 = t * t
        let t3 = t2 * t
        return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
    }

    /// 画滑动拖尾：每段独立淡出，头部再叠一个光点；不同样式用不同笔触
    private func drawTrail(
        now: Date,
        color: Color,
        size: Double,
        scale: Double,
        style: TrailStyle,
        context: GraphicsContext
    ) {
        let points = smoothedTrail(engine.trailPoints)
        guard let head = points.last else { return }

        let life = engine.trailLifetime
        let baseWidth = max(2.0, size * 0.42 * scale)
        // 减弱动态效果时，头部光晕不做呼吸缩放
        let pulse = accessibility.reduceMotion
            ? 1.0
            : 0.88 + 0.12 * sin(now.timeIntervalSinceReferenceDate * 9.0)

        if style == .brush {
            drawBrushStroke(now: now, points: points, color: color, baseWidth: baseWidth, life: life, context: context)
            return
        }

        if points.count > 1 {
            for index in 1..<points.count {
                let previous = points[index - 1]
                let current = points[index]
                let age = now.timeIntervalSince(current.time)
                let freshness = max(0, 1 - age / life)
                if freshness <= 0 { continue }

                let fade = freshness * freshness
                let width = baseWidth * (0.35 + 0.65 * freshness)
                // 用采样点自身的时间做种子，避免轨迹被裁剪时星火位置来回跳
                let pointSeed = Int(current.time.timeIntervalSinceReferenceDate * 1000)
                var segment = Path()
                segment.move(to: CGPoint(x: previous.x, y: previous.y))
                segment.addLine(to: CGPoint(x: current.x, y: current.y))

                // 这一段的方向与法线，彗星的火星和丝带的边缘靠它往两侧偏移
                let dx = current.x - previous.x
                let dy = current.y - previous.y
                let segmentLength = max(0.001, sqrt(dx * dx + dy * dy))
                let nx = -dy / segmentLength
                let ny = dx / segmentLength

                switch style {
                case .classic:
                    // 平滑变细的实体光带：柔光 + 主体 + 白色亮芯
                    context.stroke(
                        segment,
                        with: .color(color.opacity(0.16 * fade)),
                        style: StrokeStyle(lineWidth: width * 2.4, lineCap: .round)
                    )
                    context.stroke(
                        segment,
                        with: .color(color.opacity(0.85 * fade)),
                        style: StrokeStyle(lineWidth: width, lineCap: .round)
                    )
                    context.stroke(
                        segment,
                        with: .color(.white.opacity(0.28 * fade)),
                        style: StrokeStyle(lineWidth: max(1, width * 0.28), lineCap: .round)
                    )
                case .brush:
                    // 毛笔在 drawTrail 开头整条绘制，这里不会走到
                    break
                case .neon:
                    // 霓虹：灯管等宽、整体断续闪烁，外圈始终留一层辉光
                    let phase = Int(current.time.timeIntervalSinceReferenceDate * 36) % 12
                    let isLit = phase < 7
                    let neonFlicker = 0.80 + 0.20 * sin(now.timeIntervalSinceReferenceDate * 33 + Double(pointSeed % 29))
                    let glowWidth = baseWidth * (isLit ? 3.8 : 2.8)
                    context.stroke(
                        segment,
                        with: .color(color.opacity((isLit ? 0.05 : 0.012) * fade * neonFlicker)),
                        style: StrokeStyle(lineWidth: glowWidth, lineCap: .round, lineJoin: .round)
                    )
                    context.stroke(
                        segment,
                        with: .color(color.opacity((isLit ? 0.14 : 0.02) * fade * neonFlicker)),
                        style: StrokeStyle(lineWidth: glowWidth * 0.55, lineCap: .round)
                    )
                    if isLit {
                        let tube = max(1.8, baseWidth * 0.60)
                        context.stroke(
                            segment,
                            with: .color(color.opacity(0.95 * fade * neonFlicker)),
                            style: StrokeStyle(lineWidth: tube, lineCap: .round)
                        )
                        context.stroke(
                            segment,
                            with: .color(.white.opacity(0.85 * fade * neonFlicker)),
                            style: StrokeStyle(lineWidth: max(0.8, tube * 0.38), lineCap: .round)
                        )
                    }
                case .comet:
                    // 彗星：细亮脊 + 柔和尾焰，火星以不同速度往后下方散落
                    let plume = baseWidth * (0.5 + 0.8 * (1 - freshness))
                    context.stroke(
                        segment,
                        with: .color(color.opacity(0.08 * fade)),
                        style: StrokeStyle(lineWidth: plume * 1.6, lineCap: .round)
                    )
                    context.stroke(
                        segment,
                        with: .color(color.opacity(0.28 * fade)),
                        style: StrokeStyle(lineWidth: plume, lineCap: .round)
                    )
                    context.stroke(
                        segment,
                        with: .color(.white.opacity(0.75 * fade)),
                        style: StrokeStyle(lineWidth: max(1.0, baseWidth * 0.28), lineCap: .round)
                    )
                    if pointSeed % 4 == 0 {
                        let driftSpeed = 18.0 + Double(abs((pointSeed * 7) % 30))
                        let drift = max(0, age - 0.03) * driftSpeed
                        let lateral = sin(Double((pointSeed / 4) % 360) * .pi / 180) * baseWidth * 1.9
                        let sparkRadius = max(0.7, baseWidth * 0.26 * (0.5 + 0.5 * freshness))
                        var spark = Path()
                        spark.addEllipse(in: CGRect(
                            x: current.x + nx * lateral - sparkRadius,
                            y: current.y + ny * lateral + drift - sparkRadius,
                            width: sparkRadius * 2,
                            height: sparkRadius * 2
                        ))
                        context.fill(spark, with: .color(color.opacity(0.65 * fade)))
                    }
                case .ribbon:
                    // 丝带：宽而半透明的带面，宽度随采样点起伏，边缘更亮一些
                    let wobble = sin(Double(pointSeed) / 120.0) * width * 0.5
                    let bandWidth = max(width * 1.8, width * 2.8 + wobble)
                    context.stroke(
                        segment,
                        with: .color(color.opacity(0.16 * fade)),
                        style: StrokeStyle(lineWidth: bandWidth, lineCap: .round, lineJoin: .round)
                    )
                    context.stroke(
                        segment,
                        with: .color(color.opacity(0.30 * fade)),
                        style: StrokeStyle(lineWidth: bandWidth * 0.55, lineCap: .round)
                    )
                    let edgeOffset = bandWidth * 0.5
                    for side in [-1.0, 1.0] {
                        var edge = Path()
                        edge.move(to: CGPoint(
                            x: previous.x + nx * edgeOffset * side,
                            y: previous.y + ny * edgeOffset * side
                        ))
                        edge.addLine(to: CGPoint(
                            x: current.x + nx * edgeOffset * side,
                            y: current.y + ny * edgeOffset * side
                        ))
                        context.stroke(
                            edge,
                            with: .color(color.opacity(0.45 * fade)),
                            style: StrokeStyle(lineWidth: 1, lineCap: .round)
                        )
                    }
                case .stardust:
                    // 不画连续线，只留下大小不一的光点
                    let dotRadius = max(0.6, width * 0.32 + baseWidth * 0.12 * freshness)
                    var dot = Path()
                    dot.addEllipse(in: CGRect(
                        x: current.x - dotRadius,
                        y: current.y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    ))
                    context.fill(dot, with: .color(color.opacity(0.75 * fade)))
                    if pointSeed % 6 == 0 {
                        let sparkRadius = dotRadius * 0.55
                        var spark = Path()
                        spark.addEllipse(in: CGRect(
                            x: current.x - sparkRadius,
                            y: current.y - sparkRadius,
                            width: sparkRadius * 2,
                            height: sparkRadius * 2
                        ))
                        context.fill(spark, with: .color(.white.opacity(0.6 * fade)))
                    }
                }
            }
        }

        // 毛笔只留一点笔尖积墨，不做发光球
        if style == .brush {
            let brushHeadFreshness = max(0, 1 - now.timeIntervalSince(head.time) / life)
            if brushHeadFreshness > 0 {
                let dotRadius = max(1.4, baseWidth * 0.45 * (0.80 + 0.30 * brushHeadFreshness))
                var dot = Path()
                dot.addEllipse(in: CGRect(
                    x: head.x - dotRadius,
                    y: head.y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                ))
                context.fill(dot, with: .color(color.opacity(0.70 * brushHeadFreshness)))
            }
            return
        }

        // 头部光点：即使只是单击、没有移动，也能看到一下亮光
        let headFreshness = max(0, 1 - now.timeIntervalSince(head.time) / life)
        if headFreshness > 0 {
            let center = CGPoint(x: head.x, y: head.y)
            let headFactor: Double
            switch style {
            case .classic: headFactor = 1.15
            case .brush: headFactor = 0.9
            case .neon: headFactor = 0.75
            case .comet: headFactor = 1.85
            case .ribbon: headFactor = 0.7
            case .stardust: headFactor = 1.3
            }
            let haloScale: Double
            switch style {
            case .comet: haloScale = 3.6
            case .ribbon: haloScale = 2.2
            case .neon: haloScale = 2.2
            default: haloScale = 2.6
            }
            let sparkOpacity: Double
            switch style {
            case .neon: sparkOpacity = 0.95
            case .ribbon: sparkOpacity = 0.2
            case .comet: sparkOpacity = 0.9
            default: sparkOpacity = 0.75
            }
            let radius = max(3.0, baseWidth * headFactor) * (0.7 + 0.3 * headFreshness) * pulse
            var halo = Path()
            halo.addEllipse(in: CGRect(
                x: center.x - radius * haloScale,
                y: center.y - radius * haloScale,
                width: radius * haloScale * 2,
                height: radius * haloScale * 2
            ))
            context.fill(halo, with: .radialGradient(
                Gradient(colors: [color.opacity(0.42 * headFreshness), color.opacity(0)]),
                center: center,
                startRadius: 0,
                endRadius: radius * haloScale
            ))

            var core = Path()
            core.addEllipse(in: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.fill(core, with: .color(color.opacity(0.9 * headFreshness)))

            let sparkRadius = max(1.2, radius * 0.42)
            var spark = Path()
            spark.addEllipse(in: CGRect(
                x: center.x - sparkRadius,
                y: center.y - sparkRadius,
                width: sparkRadius * 2,
                height: sparkRadius * 2
            ))
            context.fill(spark, with: .color(.white.opacity(sparkOpacity * headFreshness)))

            // 彗核加一点十字星芒，和普通光点区分开
            if style == .comet {
                let flareLength = radius * 2.8
                var flare = Path()
                flare.move(to: CGPoint(x: center.x - flareLength, y: center.y))
                flare.addLine(to: CGPoint(x: center.x + flareLength, y: center.y))
                flare.move(to: CGPoint(x: center.x, y: center.y - flareLength))
                flare.addLine(to: CGPoint(x: center.x, y: center.y + flareLength))
                context.stroke(
                    flare,
                    with: .color(.white.opacity(0.40 * headFreshness)),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
            }
        }
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
        // 开启「减弱动态效果」时，旋转与摇摆的幅度收到 1/5，尽量只保留位移和淡出
        let motion = accessibility.reduceMotion ? 0.2 : 1.0

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
            let rotation = particle.angle + progress * (.pi * 1.5) * motion + particle.variation
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
            pixelContext.rotate(by: .radians((progress * 3.2 + particle.variation * 6.3) * motion))
            let square = Path(CGRect(x: -side / 2, y: -side / 2, width: side, height: side))
            pixelContext.fill(square, with: .color(color.opacity(fade)))

        case .hearts:
            // 爱心上浮 + 轻微摇摆旋转，按 variation 错峰起飞避免一开始挤成一坨
            let localP = min(1, progress * 1.12 + particle.variation * 0.10)
            let easedHeart = localP * (2 - localP)
            let spread = radius * scale * particle.intensity
            let lift = easedHeart * spread * 1.8
            let sway = sin(localP * .pi * 2.4 + particle.variation * 4) * spread * 0.22 * motion
            let heartX = particle.x + cosA * spread * 1.05 * easedHeart + sway
            let heartY = particle.y + sinA * spread * 0.28 * easedHeart - lift
                - particle.variation * boostedSize * 0.9
            let heartSize = max(9, boostedSize * 2.2 * (0.70 + 0.40 * (1 - easedHeart)))
            var heartContext = context
            heartContext.opacity = fade * 0.95
            heartContext.translateBy(x: heartX, y: heartY)
            heartContext.rotate(by: .radians(sin(localP * .pi * 1.6 + particle.variation * 3) * 0.32 * motion))
            heartContext.fill(heartPath(size: heartSize), with: .color(color))

        case .emoji:
            let popProgress = min(1, progress / 0.2)
            let popEase = 1 - pow(1 - popProgress, 3)
            let lift = eased * radius * scale * 0.65
            let sway = sin(progress * .pi * 2.2 + particle.variation * 5) * size * 0.35 * fade * motion
            let emojiScale = max(0.01, (0.45 + popEase * 0.55) * particle.intensity)
            let rotation = sin(progress * .pi * 1.4 + particle.variation * 3) * 0.16 * motion
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

        case .firework:
            // 焰火：向外炸开后受重力下坠，每颗粒子拖一条渐隐尾迹
            let spread = radius * scale * particle.intensity
            let gravity = eased * eased * spread * 0.85
            let headX = particle.x + distance * cosA
            let headY = particle.y + distance * sinA + gravity
            let trailLength = max(3, boostedSize * (1.6 - progress))
            let tailX = headX - trailLength * cosA
            let tailY = headY - trailLength * sinA

            var trail = Path()
            trail.move(to: CGPoint(x: tailX, y: tailY))
            trail.addLine(to: CGPoint(x: headX, y: headY))
            context.stroke(
                trail,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0), color.opacity(fade * 0.7)]),
                    startPoint: CGPoint(x: tailX, y: tailY),
                    endPoint: CGPoint(x: headX, y: headY)
                ),
                style: StrokeStyle(lineWidth: max(1.2, boostedSize * 0.15), lineCap: .round)
            )

            let headRadius = max(1, boostedSize * 0.17 * (0.6 + 0.4 * fade))
            var head = Path()
            head.addEllipse(in: CGRect(
                x: headX - headRadius,
                y: headY - headRadius,
                width: headRadius * 2,
                height: headRadius * 2
            ))
            context.fill(head, with: .color(color.opacity(fade * 0.95)))

            if particle.variation < 0.001 {
                let flashRadius = max(2, spread * 0.24 * (0.35 + eased * 0.65))
                var flash = Path()
                flash.addEllipse(in: CGRect(
                    x: particle.x - flashRadius,
                    y: particle.y - flashRadius,
                    width: flashRadius * 2,
                    height: flashRadius * 2
                ))
                context.fill(
                    flash,
                    with: .radialGradient(
                        Gradient(colors: [color.opacity(fade * 0.5), color.opacity(0)]),
                        center: CGPoint(x: particle.x, y: particle.y),
                        startRadius: 0,
                        endRadius: flashRadius
                    )
                )
            }

        case .bolt:
            // 闪电：沿角度折出 5 段锯齿，宽发光 + 细亮芯
            let span = radius * scale * particle.intensity
                * (0.45 + particle.variation * 0.55)
            let normalX = -sinA
            let normalY = cosA
            var points: [CGPoint] = [CGPoint(x: particle.x, y: particle.y)]
            for segment in 1...5 {
                let t = Double(segment) / 5.0
                let jitter = sin(t * 11 + particle.variation * 97 + Double(segment) * 13.7)
                    * boostedSize * 0.9 * (1 - t * 0.35) * motion
                points.append(CGPoint(
                    x: particle.x + span * t * cosA + normalX * jitter,
                    y: particle.y + span * t * sinA + normalY * jitter
                ))
            }

            var bolt = Path()
            bolt.move(to: points[0])
            for point in points.dropFirst() {
                bolt.addLine(to: point)
            }
            context.stroke(
                bolt,
                with: .color(color.opacity(fade * 0.22)),
                style: StrokeStyle(lineWidth: max(4, boostedSize * 0.7), lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                bolt,
                with: .color(color.opacity(fade)),
                style: StrokeStyle(lineWidth: max(1.4, boostedSize * 0.16), lineCap: .round, lineJoin: .round)
            )

            if particle.variation < 0.08 {
                let coreRadius = max(2, boostedSize * 0.55 * (1 - eased * 0.5))
                var core = Path()
                core.addEllipse(in: CGRect(
                    x: particle.x - coreRadius,
                    y: particle.y - coreRadius,
                    width: coreRadius * 2,
                    height: coreRadius * 2
                ))
                context.fill(core, with: .color(color.opacity(fade * 0.9)))
            }
        }
    }
}

@MainActor
final class GlobalMouseMonitor: ObservableObject {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var motionGlobalMonitor: Any?
    private var motionLocalMonitor: Any?
    /// 记录当前是否需要移动监听，权限变化重建时好恢复
    private var isTrailMotionActive = false

    func start(engine: EffectEngine) {
        guard globalMonitor == nil, localMonitor == nil else { return }

        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak engine] event in
            guard Self.supports(event) else { return }
            DispatchQueue.main.async {
                guard let point = OverlayGeometry.mousePoint() else { return }
                engine?.trigger(at: point)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak engine] event in
            if Self.supports(event), let point = OverlayGeometry.mousePoint() {
                engine?.trigger(at: point)
            }
            return event
        }
    }

    /// 右键 / 中键是否也出效果，交给设置决定
    private static func supports(_ event: NSEvent) -> Bool {
        switch event.type {
        case .rightMouseDown, .otherMouseDown:
            return AppState.shared.rightClickEnabled
        default:
            return true
        }
    }

    /// 拖尾开关打开时才安装移动监听，关闭时及时释放事件通道
    func syncTrailMotion(enabled: Bool, engine: EffectEngine) {
        isTrailMotionActive = enabled
        if enabled {
            startTrailMotion(engine: engine)
        } else {
            stopTrailMotion()
        }
    }

    private func startTrailMotion(engine: EffectEngine) {
        guard motionGlobalMonitor == nil, motionLocalMonitor == nil else { return }

        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]

        motionGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak engine] event in
            guard Self.supportsMotion(event) else { return }
            DispatchQueue.main.async {
                guard let point = OverlayGeometry.mousePoint() else { return }
                engine?.extendTrail(at: point)
            }
        }

        motionLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak engine] event in
            if Self.supportsMotion(event), let point = OverlayGeometry.mousePoint() {
                engine?.extendTrail(at: point)
            }
            return event
        }
    }

    private func stopTrailMotion() {
        if let motionGlobalMonitor {
            NSEvent.removeMonitor(motionGlobalMonitor)
            self.motionGlobalMonitor = nil
        }
        if let motionLocalMonitor {
            NSEvent.removeMonitor(motionLocalMonitor)
            self.motionLocalMonitor = nil
        }
    }

    /// 拖动右键 / 中键是否也留拖尾，和点击效果用同一个开关
    private static func supportsMotion(_ event: NSEvent) -> Bool {
        switch event.type {
        case .rightMouseDragged, .otherMouseDragged:
            return AppState.shared.rightClickEnabled
        default:
            return true
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
        stopTrailMotion()
        isTrailMotionActive = false
    }

    /// 输入监控权限变化后重建监听：早期注册的监听不会随权限自动开始投递事件。
    func restart(engine: EffectEngine) {
        let trailWasActive = isTrailMotionActive
        stop()
        start(engine: engine)
        if trailWasActive {
            syncTrailMotion(enabled: true, engine: engine)
        }
    }
}
