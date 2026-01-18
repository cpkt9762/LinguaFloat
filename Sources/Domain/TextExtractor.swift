import Foundation
import AppKit
import ApplicationServices

final class TextExtractor {
    static let shared = TextExtractor()
    
    private init() {}
    
    func getSelectedText() -> String? {
        if let text = getSelectedTextViaAccessibility() {
            return text
        }
        
        return ClipboardManager.shared.copySelectedText()
    }
    
    func getFocusedTextFieldContent() -> String? {
        if let text = getFocusedTextFieldContentViaAccessibility() {
            return text
        }
        
        return ClipboardManager.shared.getFieldContentViaClipboard()
    }
    
    private func getFocusedTextFieldContentViaAccessibility() -> String? {
        guard let focusedElement = getFocusedElement() else { return nil }
        
        var value: AnyObject?
        AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &value)
        
        if let text = value as? String, !text.isEmpty {
            return text
        }
        
        return nil
    }
    
    private func getSelectedTextViaAccessibility() -> String? {
        guard PermissionManager.shared.isAccessibilityEnabled else { return nil }
        
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?
        AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        
        guard let app = focusedApp else { return nil }
        
        var focusedElement: AnyObject?
        AXUIElementCopyAttributeValue(app as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard let element = focusedElement else { return nil }
        
        var selectedText: AnyObject?
        AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)
        
        return selectedText as? String
    }
    
    private func getFocusedElement() -> AXUIElement? {
        guard PermissionManager.shared.isAccessibilityEnabled else { return nil }
        
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?
        AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        
        guard let app = focusedApp else { return nil }
        
        var focusedElement: AnyObject?
        AXUIElementCopyAttributeValue(app as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        return focusedElement as! AXUIElement?
    }
    
}
