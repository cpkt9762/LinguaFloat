import AppKit

final class ClipboardManager {
    static let shared = ClipboardManager()
    
    private var savedItems: [NSPasteboardItem]?
    
    private init() {}
    
    func save() {
        let pasteboard = NSPasteboard.general
        savedItems = pasteboard.pasteboardItems?.compactMap { item in
            let newItem = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    newItem.setData(data, forType: type)
                }
            }
            return newItem
        }
    }
    
    func restore() {
        guard let items = savedItems else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
        savedItems = nil
    }
    
    func getText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
    
    func setText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func copySelectedText() -> String? {
        save()
        
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        let copiedText = getText()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.restore()
        }
        
        return copiedText
    }
    
    func selectAll() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    func paste() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    func replaceFieldContent(with newText: String) {
        save()
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            self?.selectAll()
            Thread.sleep(forTimeInterval: 0.1)
            
            DispatchQueue.main.sync {
                self?.setText(newText)
            }
            Thread.sleep(forTimeInterval: 0.05)
            
            self?.paste()
            
            Thread.sleep(forTimeInterval: 0.2)
            DispatchQueue.main.async {
                self?.restore()
            }
        }
    }
    
    func getFieldContentViaClipboard() -> String? {
        save()
        
        let source = CGEventSource(stateID: .hidSystemState)
        
        let aKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: true)
        let aKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: false)
        aKeyDown?.flags = .maskCommand
        aKeyUp?.flags = .maskCommand
        aKeyDown?.post(tap: .cghidEventTap)
        aKeyUp?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        let cKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        let cKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cKeyDown?.flags = .maskCommand
        cKeyUp?.flags = .maskCommand
        cKeyDown?.post(tap: .cghidEventTap)
        cKeyUp?.post(tap: .cghidEventTap)
        
        Thread.sleep(forTimeInterval: 0.1)
        
        let copiedText = getText()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.restore()
        }
        
        return copiedText
    }
}
