import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let translateSelection = Self(
        "translateSelection",
        default: .init(.t, modifiers: [.command, .shift])
    )
    static let ocrCapture = Self(
        "ocrCapture",
        default: .init(.o, modifiers: [.command, .shift])
    )
    static let showHistory = Self(
        "showHistory",
        default: .init(.h, modifiers: [.command, .shift])
    )
}

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }
            
            TranslationSettingsView()
                .tabItem {
                    Label("翻译", systemImage: "text.bubble")
                }
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("快捷键", systemImage: "command")
                }
            
            AdvancedSettingsView()
                .tabItem {
                    Label("高级", systemImage: "gearshape.2")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 520, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("autoLaunch") private var autoLaunch = false
    @AppStorage("showInDock") private var showInDock = false
    @AppStorage("hoverWordEnabled") private var hoverWordEnabled = false
    @AppStorage("hoverDelay") private var hoverDelay = 0.5
    
    var body: some View {
        Form {
            Section("启动") {
                Toggle("登录时自动启动", isOn: $autoLaunch)
                Toggle("在 Dock 中显示图标", isOn: $showInDock)
            }
            
            Section("悬停取词") {
                Toggle("启用悬停取词模式", isOn: $hoverWordEnabled)
                
                if hoverWordEnabled {
                    HStack {
                        Text("悬停延迟")
                        Slider(value: $hoverDelay, in: 0.2...2.0, step: 0.1)
                        Text("\(hoverDelay, specifier: "%.1f") 秒")
                            .foregroundStyle(.secondary)
                            .frame(width: 50)
                    }
                    
                    Text("鼠标悬停在文字上方时自动识别并翻译")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct TranslationSettingsView: View {
    @AppStorage("smartDetection") private var smartDetection = true
    @AppStorage("defaultTargetLanguage") private var defaultTargetLanguage = "zh-CN"
    @AppStorage("chineseToLanguage") private var chineseToLanguage = "en"
    @AppStorage("defaultProvider") private var defaultProvider = "google"
    @AppStorage("autoSaveHistory") private var autoSaveHistory = true
    
    private let languageOptions = [
        ("zh-CN", "简体中文"),
        ("zh-TW", "繁体中文"),
        ("en", "英语"),
        ("ja", "日语"),
        ("ko", "韩语"),
        ("fr", "法语"),
        ("de", "德语"),
        ("es", "西班牙语")
    ]
    
    private let providerOptions = [
        ("google", "Google 翻译"),
        ("openai", "OpenAI GPT"),
        ("claude", "Anthropic Claude"),
        ("deepseek", "DeepSeek")
    ]
    
    var body: some View {
        Form {
            Section("翻译引擎") {
                Picker("默认翻译引擎", selection: $defaultProvider) {
                    ForEach(providerOptions, id: \.0) { id, name in
                        Text(name).tag(id)
                    }
                }
            }
            
            Section("语言设置") {
                Toggle("智能语言检测", isOn: $smartDetection)
                
                Picker("默认目标语言", selection: $defaultTargetLanguage) {
                    ForEach(languageOptions, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
                
                HStack {
                    Text("中文内容翻译为")
                    Spacer()
                    Picker("", selection: $chineseToLanguage) {
                        ForEach(languageOptions.filter { $0.0 != "zh-CN" }, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            }
            
            Section("历史记录") {
                Toggle("自动保存翻译历史", isOn: $autoSaveHistory)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ShortcutsSettingsView: View {
    @AppStorage("quickTranslateDirection") private var quickTranslateDirection = 0
    @State private var accessibilityGranted = AXIsProcessTrusted()
    @State private var inputMonitoringGranted = PermissionManager.shared.isInputMonitoringEnabled
    
    private var allPermissionsGranted: Bool {
        accessibilityGranted && inputMonitoringGranted
    }
    
    var body: some View {
        Form {
            Section("权限") {
                HStack {
                    Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(accessibilityGranted ? .green : .red)
                    Text("辅助功能")
                    Spacer()
                    if !accessibilityGranted {
                        Button("授权") {
                            PermissionManager.shared.openAccessibilitySettings()
                        }
                    } else {
                        Text("已授权")
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: inputMonitoringGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(inputMonitoringGranted ? .green : .red)
                    Text("输入监控")
                    Spacer()
                    if !inputMonitoringGranted {
                        Button("授权") {
                            PermissionManager.shared.openInputMonitoringSettings()
                        }
                    } else {
                        Text("已授权")
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !allPermissionsGranted {
                    Text("快速翻译替换功能需要上述权限才能使用")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    
                    Button("重置权限并重新授权") {
                        resetAndRequestPermissions()
                    }
                    .foregroundStyle(.red)
                }
            }
            
            Section("全局快捷键") {
                KeyboardShortcuts.Recorder("翻译选中文本（浮窗）", name: .translateSelection)
                KeyboardShortcuts.Recorder("OCR 截图识别", name: .ocrCapture)
                KeyboardShortcuts.Recorder("显示翻译历史", name: .showHistory)
            }
            
            Section("快速翻译替换 ⌘A → R → V") {
                Picker("翻译方向", selection: $quickTranslateDirection) {
                    Text("中文 → 英语").tag(0)
                    Text("英语 → 中文").tag(1)
                }
                .pickerStyle(.segmented)
                
                Text("在输入框中按 ⌘A 全选后，不松开 ⌘ 继续按 R 翻译，翻译结果自动复制到剪贴板，再按 V 粘贴替换")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            refreshPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissions()
        }
    }
    
    private func refreshPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
        inputMonitoringGranted = PermissionManager.shared.isInputMonitoringEnabled
    }
    
    private func resetAndRequestPermissions() {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.pingzi.LinguaFloat"
        
        let alert = NSAlert()
        alert.messageText = "重置权限"
        alert.informativeText = "将清除 LinguaFloat 的现有权限记录，然后重新请求授权。\n\n执行后请在系统设置中重新勾选 LinguaFloat。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            Task {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
                process.arguments = ["reset", "Accessibility", bundleId]
                try? process.run()
                process.waitUntilExit()
                
                let process2 = Process()
                process2.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
                process2.arguments = ["reset", "ListenEvent", bundleId]
                try? process2.run()
                process2.waitUntilExit()
                
                await MainActor.run {
                    PermissionManager.shared.openAccessibilitySettings()
                }
            }
        }
    }
}

extension Notification.Name {
    static let accessibilityPermissionGranted = Notification.Name("accessibilityPermissionGranted")
}

struct PermissionStatusView: View {
    @State private var accessibilityGranted = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(accessibilityGranted ? .green : .red)
                Text("辅助功能权限")
                Spacer()
                if !accessibilityGranted {
                    Button("授权") {
                        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                        AXIsProcessTrustedWithOptions(options)
                    }
                    .buttonStyle(.link)
                }
            }
            
            Text("需要授予「输入监控」和「辅助功能」权限才能使用三连空格功能")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            accessibilityGranted = AXIsProcessTrusted()
        }
    }
}

struct AdvancedSettingsView: View {
    @AppStorage("autoCopyOCR") private var autoCopyOCR = false
    @AppStorage("animationsEnabled") private var animationsEnabled = true
    @AppStorage("autoDismissDelay") private var autoDismissDelay = 0.0
    
    var body: some View {
        Form {
            Section("OCR 设置") {
                Toggle("自动复制 OCR 识别结果", isOn: $autoCopyOCR)
            }
            
            Section("界面") {
                Toggle("启用动画效果", isOn: $animationsEnabled)
                
                HStack {
                    Text("自动关闭浮层")
                    Slider(value: $autoDismissDelay, in: 0...10, step: 1)
                    if autoDismissDelay == 0 {
                        Text("关闭")
                            .foregroundStyle(.secondary)
                            .frame(width: 50)
                    } else {
                        Text("\(Int(autoDismissDelay)) 秒")
                            .foregroundStyle(.secondary)
                            .frame(width: 50)
                    }
                }
            }
            
            Section("数据") {
                Button("清除所有翻译历史", role: .destructive) {
                    Task { @MainActor in
                        HistoryService.shared.deleteAll()
                    }
                }
                
                Button("重置所有设置") {
                    resetAllSettings()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func resetAllSettings() {
        let defaults = UserDefaults.standard
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "translate")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("LinguaFloat")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("版本 1.0.0 (Build 1)")
                .foregroundStyle(.secondary)
            
            Text("macOS 翻译与 AI 辅助学习工具")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 4) {
                Link("访问项目主页", destination: URL(string: "https://github.com/pingzi/LinguaFloat")!)
                Link("反馈问题", destination: URL(string: "https://github.com/pingzi/LinguaFloat/issues")!)
            }
            .font(.caption)
            
            Spacer()
            
            Text("© 2024 Pingzi. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
}
