import Foundation
import AppKit
import ApplicationServices

@MainActor
final class HoverWordService: ObservableObject {
    static let shared = HoverWordService()
    
    @Published var isEnabled = false
    @Published var currentWord: String?
    @Published var hoverPosition: CGPoint = .zero
    
    private var eventMonitor: Any?
    private var hoverTimer: Timer?
    private let hoverDelay: TimeInterval = 0.5
    private var lastMousePosition: CGPoint = .zero
    
    var onWordDetected: ((String, CGPoint) -> Void)?
    
    private init() {}
    
    func start() {
        guard !isEnabled else { return }
        
        guard AXIsProcessTrusted() else {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return
        }
        
        isEnabled = true
        startMouseTracking()
    }
    
    func stop() {
        isEnabled = false
        stopMouseTracking()
        currentWord = nil
    }
    
    private func startMouseTracking() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseMove(event.locationInWindow)
            }
        }
    }
    
    private func stopMouseTracking() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        hoverTimer?.invalidate()
        hoverTimer = nil
    }
    
    private func handleMouseMove(_ position: CGPoint) {
        let screenPosition = NSEvent.mouseLocation
        
        let distance = hypot(screenPosition.x - lastMousePosition.x, screenPosition.y - lastMousePosition.y)
        
        if distance > 5 {
            lastMousePosition = screenPosition
            hoverTimer?.invalidate()
            
            hoverTimer = Timer.scheduledTimer(withTimeInterval: hoverDelay, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.detectWordAtPosition(screenPosition)
                }
            }
        }
    }
    
    private func detectWordAtPosition(_ position: CGPoint) {
        guard isEnabled else { return }
        
        guard let word = getWordAtMousePosition() else {
            currentWord = nil
            return
        }
        
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWord.isEmpty, trimmedWord.count > 1 else {
            currentWord = nil
            return
        }
        
        currentWord = trimmedWord
        hoverPosition = position
        onWordDetected?(trimmedWord, position)
    }
    
    private func getWordAtMousePosition() -> String? {
        let systemElement = AXUIElementCreateSystemWide()
        var element: AXUIElement?
        let mouseLocation = NSEvent.mouseLocation
        
        guard let mainScreen = NSScreen.main else { return nil }
        
        let point = CGPoint(
            x: mouseLocation.x,
            y: mainScreen.frame.height - mouseLocation.y
        )
        
        let result = AXUIElementCopyElementAtPosition(systemElement, Float(point.x), Float(point.y), &element)
        
        guard result == .success, let element = element else {
            return nil
        }
        
        var value: CFTypeRef?
        let valueResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)
        
        if valueResult == .success, let text = value as? String {
            return extractWordFromText(text, element: element)
        }
        
        let selectedResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value)
        if selectedResult == .success, let selectedText = value as? String, !selectedText.isEmpty {
            return selectedText
        }
        
        return nil
    }
    
    private func extractWordFromText(_ text: String, element: AXUIElement) -> String? {
        var insertionPointValue: CFTypeRef?
        let pointResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &insertionPointValue)
        
        if pointResult == .success, let axValue = insertionPointValue {
            var range = CFRange()
            if AXValueGetValue(axValue as! AXValue, .cfRange, &range) {
                let index = range.location
                if index >= 0 && index < text.count {
                    return extractWordAtIndex(text, index: index)
                }
            }
        }
        
        return extractFirstWord(from: text)
    }
    
    private func extractWordAtIndex(_ text: String, index: Int) -> String? {
        let nsString = text as NSString
        guard index < nsString.length else { return nil }
        
        let range = nsString.rangeOfComposedCharacterSequence(at: index)
        let wordRange = expandToWordBoundary(in: nsString, from: range)
        
        guard wordRange.location != NSNotFound else { return nil }
        
        return nsString.substring(with: wordRange)
    }
    
    private func expandToWordBoundary(in string: NSString, from range: NSRange) -> NSRange {
        var start = range.location
        var end = range.location + range.length
        
        let wordCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-'"))
        let chineseRange = Unicode.Scalar(0x4E00)!...Unicode.Scalar(0x9FFF)!
        
        while start > 0 {
            let prevIndex = start - 1
            let char = string.character(at: prevIndex)
            let scalar = Unicode.Scalar(char)
            
            if let scalar = scalar {
                if chineseRange.contains(scalar) || wordCharacters.contains(scalar) {
                    start = prevIndex
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        while end < string.length {
            let char = string.character(at: end)
            let scalar = Unicode.Scalar(char)
            
            if let scalar = scalar {
                if chineseRange.contains(scalar) || wordCharacters.contains(scalar) {
                    end += 1
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return NSRange(location: start, length: end - start)
    }
    
    private func extractFirstWord(from text: String) -> String? {
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components.first { !$0.isEmpty }
    }
}
