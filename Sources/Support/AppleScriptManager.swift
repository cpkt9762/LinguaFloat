import AppKit
import Carbon

protocol AppScriptHandler {
    var processName: String { get }
    var bundleIdentifier: String { get }
    
    func getInputFieldContent() -> String?
    func setInputFieldContent(_ text: String) -> Bool
}

final class AppleScriptManager {
    static let shared = AppleScriptManager()
    
    private var handlers: [String: AppScriptHandler] = [:]
    
    private init() {
        registerHandler(WeChatScriptHandler())
    }
    
    func registerHandler(_ handler: AppScriptHandler) {
        handlers[handler.bundleIdentifier] = handler
    }
    
    func getFrontmostAppBundleId() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }
    
    func hasHandler(for bundleId: String) -> Bool {
        handlers[bundleId] != nil
    }
    
    func getInputFieldContent(for bundleId: String) -> String? {
        handlers[bundleId]?.getInputFieldContent()
    }
    
    func setInputFieldContent(_ text: String, for bundleId: String) -> Bool {
        handlers[bundleId]?.setInputFieldContent(text) ?? false
    }
    
    func getInputFieldContentForFrontmostApp() -> String? {
        guard let bundleId = getFrontmostAppBundleId() else { return nil }
        return getInputFieldContent(for: bundleId)
    }
    
    func setInputFieldContentForFrontmostApp(_ text: String) -> Bool {
        guard let bundleId = getFrontmostAppBundleId() else { return false }
        return setInputFieldContent(text, for: bundleId)
    }
    
    @discardableResult
    func runAppleScript(_ script: String) -> (success: Bool, result: String?, error: String?) {
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        let result = appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            return (false, nil, errorMessage)
        }
        
        return (true, result?.stringValue, nil)
    }
}

struct WeChatScriptHandler: AppScriptHandler {
    let processName = "WeChat"
    let bundleIdentifier = "com.tencent.xinWeChat"
    
    func getInputFieldContent() -> String? {
        let script = """
        tell application "System Events"
            tell process "WeChat"
                tell window 1
                    tell splitter group 1
                        tell splitter group 1
                            tell scroll area 2
                                return value of text area 1
                            end tell
                        end tell
                    end tell
                end tell
            end tell
        end tell
        """
        
        let result = AppleScriptManager.shared.runAppleScript(script)
        return result.success ? result.result : nil
    }
    
    func setInputFieldContent(_ text: String) -> Bool {
        let escapedText = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let script = """
        tell application "System Events"
            tell process "WeChat"
                tell window 1
                    tell splitter group 1
                        tell splitter group 1
                            tell scroll area 2
                                set value of text area 1 to "\(escapedText)"
                            end tell
                        end tell
                    end tell
                end tell
            end tell
        end tell
        """
        
        let result = AppleScriptManager.shared.runAppleScript(script)
        return result.success
    }
}
