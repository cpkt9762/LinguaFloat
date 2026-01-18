import Foundation
import Carbon
import AppKit

final class TriggerManager {
    static let shared = TriggerManager()
    
    var onTripleSpaceTrigger: (() -> Void)?
    var onHotkeyTrigger: (() -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var spaceTimestamps: [Date] = []
    private let tripleSpaceWindow: TimeInterval = 0.8
    private let cooldownInterval: TimeInterval = 1.5
    private var lastTriggerTime: Date?
    private var isMonitoring = false
    
    private init() {}
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        guard AXIsProcessTrusted() else {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            return
        }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else {
                    return Unmanaged.passRetained(event)
                }
                let manager = Unmanaged<TriggerManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else { return }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        isMonitoring = true
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        spaceTimestamps.removeAll()
        isMonitoring = false
    }
    
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        guard keyCode == 49 else {
            spaceTimestamps.removeAll()
            return Unmanaged.passRetained(event)
        }
        
        let flags = event.flags
        let hasModifiers = flags.contains(.maskCommand) ||
                          flags.contains(.maskControl) ||
                          flags.contains(.maskAlternate) ||
                          flags.contains(.maskShift)
        
        guard !hasModifiers else {
            spaceTimestamps.removeAll()
            return Unmanaged.passRetained(event)
        }
        
        let now = Date()
        spaceTimestamps.append(now)
        spaceTimestamps = spaceTimestamps.filter { now.timeIntervalSince($0) < tripleSpaceWindow }
        
        if spaceTimestamps.count >= 3 {
            if let lastTrigger = lastTriggerTime, now.timeIntervalSince(lastTrigger) < cooldownInterval {
                spaceTimestamps.removeAll()
                return Unmanaged.passRetained(event)
            }
            
            lastTriggerTime = now
            spaceTimestamps.removeAll()
            
            DispatchQueue.main.async { [weak self] in
                self?.onTripleSpaceTrigger?()
            }
        }
        
        return Unmanaged.passRetained(event)
    }
}
