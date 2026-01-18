import AppKit
import SwiftUI
import KeyboardShortcuts
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var historyWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var sequenceMonitor: SequenceKeyMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupKeyboardShortcuts()
        setupSequenceMonitor()
    }
    
    private func setupKeyboardShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .translateSelection) { [weak self] in
            self?.translateToPopover()
        }
        
        KeyboardShortcuts.onKeyUp(for: .ocrCapture) { [weak self] in
            self?.ocrCapture()
        }
        
        KeyboardShortcuts.onKeyUp(for: .showHistory) { [weak self] in
            self?.showHistory()
        }
    }
    
    private func setupSequenceMonitor() {
        sequenceMonitor = SequenceKeyMonitor()
        sequenceMonitor?.onTranslateTrigger = { [weak self] in
            self?.translateToClipboard()
        }
        sequenceMonitor?.start()
    }
    
    private func showHint(_ message: String) {
        let panel = FloatingPanelController.shared
        let hintView = TripleSpaceHintView(message: message)
        panel.show(content: hintView, near: NSEvent.mouseLocation, animated: true, autoDismiss: 2.0)
    }
    
    private func translateToPopover() {
        Task { @MainActor in
            if !PermissionManager.shared.isAccessibilityEnabled {
                PermissionManager.shared.requestAccessibilityPermission()
                return
            }
            
            guard let text = TextExtractor.shared.getSelectedText(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                showHint("请先选中文本")
                return
            }
            
            let panel = FloatingPanelController.shared
            let popoverView = TranslationPopoverView(
                translationService: TranslationService.shared,
                onClose: {
                    FloatingPanelController.shared.hide()
                },
                onRetry: {
                    Task { @MainActor in
                        await TranslationService.shared.translate(text: text, sourceType: .selection)
                    }
                }
            )
            panel.show(content: popoverView, near: NSEvent.mouseLocation, animated: true)
            
            await TranslationService.shared.translate(text: text, sourceType: .selection)
        }
    }
    
    private func translateToClipboard() {
        Task { @MainActor in
            if !PermissionManager.shared.isAccessibilityEnabled {
                PermissionManager.shared.requestAccessibilityPermission()
                return
            }
            
            guard let text = TextExtractor.shared.getSelectedText(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                showHint("请先选中文本")
                return
            }
            
            let direction = SettingsStore.shared.quickTranslateDirection
            
            await TranslationService.shared.translate(
                text: text,
                sourceLanguage: direction.sourceLanguage,
                targetLanguage: direction.targetLanguage,
                sourceType: .selection
            )
            
            if let result = TranslationService.shared.lastResult {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(result.translatedText, forType: .string)
                
                simulatePaste()
            } else if TranslationService.shared.lastError != nil {
                showHint("翻译失败")
            }
        }
    }
    
    private func simulatePaste() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let frontApp = NSWorkspace.shared.frontmostApplication else {
                self?.showHint("已复制，请手动粘贴 (Cmd+V)")
                return
            }
            
            let pid = frontApp.processIdentifier
            let appRef = AXUIElementCreateApplication(pid)
            
            var menuBar: CFTypeRef?
            guard AXUIElementCopyAttributeValue(appRef, kAXMenuBarAttribute as CFString, &menuBar) == .success,
                  let menuBarRef = menuBar else {
                self?.showHint("已复制，请手动粘贴 (Cmd+V)")
                return
            }
            
            let success = Self.clickMenuItem(menuBarRef as! AXUIElement, path: ["编辑", "粘贴"]) ||
                          Self.clickMenuItem(menuBarRef as! AXUIElement, path: ["Edit", "Paste"])
            if !success {
                self?.showHint("已复制，请手动粘贴 (Cmd+V)")
            }
        }
    }
    
    private static func clickMenuItem(_ menuBar: AXUIElement, path: [String]) -> Bool {
        var current: AXUIElement = menuBar
        
        for (index, title) in path.enumerated() {
            var children: CFTypeRef?
            guard AXUIElementCopyAttributeValue(current, kAXChildrenAttribute as CFString, &children) == .success,
                  let items = children as? [AXUIElement] else {
                return false
            }
            
            var foundItem: AXUIElement?
            for item in items {
                var itemTitle: CFTypeRef?
                if AXUIElementCopyAttributeValue(item, kAXTitleAttribute as CFString, &itemTitle) == .success,
                   let t = itemTitle as? String, t.contains(title) {
                    foundItem = item
                    break
                }
            }
            
            guard let item = foundItem else { return false }
            
            if index < path.count - 1 {
                var subMenu: CFTypeRef?
                if AXUIElementCopyAttributeValue(item, kAXChildrenAttribute as CFString, &subMenu) == .success,
                   let subMenuItems = subMenu as? [AXUIElement], let first = subMenuItems.first {
                    current = first
                } else {
                    return false
                }
            } else {
                current = item
            }
        }
        
        return AXUIElementPerformAction(current, kAXPressAction as CFString) == .success
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "translate", accessibilityDescription: "LinguaFloat")
            button.action = #selector(handleStatusItemClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 360, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: TranslateView())
    }
    
    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }
    
    private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        let translateItem = NSMenuItem(title: "翻译选中文本", action: #selector(translateSelection), keyEquivalent: "t")
        translateItem.target = self
        menu.addItem(translateItem)
        
        let ocrItem = NSMenuItem(title: "OCR 截图", action: #selector(ocrCapture), keyEquivalent: "o")
        ocrItem.target = self
        menu.addItem(ocrItem)
        
        let historyItem = NSMenuItem(title: "翻译历史", action: #selector(showHistory), keyEquivalent: "h")
        historyItem.target = self
        menu.addItem(historyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出 LinguaFloat", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func translateSelection() {
        translateToPopover()
    }
    
    @objc private func ocrCapture() {
        Task { @MainActor in
            do {
                let text = try await OCRService.shared.captureAndRecognize()
                showOCRResult(text)
            } catch let error as OCRError where error.isCancelled {
                return
            } catch {
                showOCRError(error)
            }
        }
    }
    
    private func showOCRResult(_ text: String) {
        if SettingsStore.shared.autoCopyOCR {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }
        
        let panel = FloatingPanelController.shared
        let popoverView = TranslationPopoverView(
            translationService: TranslationService.shared,
            onClose: {
                FloatingPanelController.shared.hide()
            },
            onRetry: {
                Task { @MainActor in
                    await TranslationService.shared.translate(text: text, sourceType: .ocr)
                }
            }
        )
        panel.show(content: popoverView, near: NSEvent.mouseLocation, animated: true)
        
        Task { @MainActor in
            await TranslationService.shared.translate(text: text, sourceType: .ocr)
        }
    }
    
    private func showOCRError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "OCR 识别失败"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    @objc private func showHistory() {
        if let window = historyWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "翻译历史"
        window.contentViewController = NSHostingController(rootView: HistoryView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        historyWindow = window
    }
    
    @objc private func openSettings() {
        NSApp.setActivationPolicy(.regular)
        
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.contentViewController = NSHostingController(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        settingsWindow = window
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.makeFirstResponder(window.contentView)
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === settingsWindow {
            settingsWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
}
