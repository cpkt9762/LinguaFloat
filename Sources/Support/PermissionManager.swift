import Foundation
import AppKit
import ApplicationServices

final class PermissionManager {
    static let shared = PermissionManager()
    
    private init() {}
    
    var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }
    
    var isInputMonitoringEnabled: Bool {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        if let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        ) {
            CGEvent.tapEnable(tap: tap, enable: false)
            return true
        }
        return false
    }
    
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    func openInputMonitoringSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
    }
    
    func resetPermissions() {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.pingzi.LinguaFloat"
        let script = """
        do shell script "tccutil reset Accessibility \(bundleId); tccutil reset ListenEvent \(bundleId)" with administrator privileges
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }
}
