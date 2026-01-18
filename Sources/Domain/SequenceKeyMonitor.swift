import Foundation
import AppKit
import Carbon

final class SequenceKeyMonitor {
    var onTranslateTrigger: (() -> Void)?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var cmdAPressedTime: Date?
    private let sequenceTimeout: TimeInterval = 1.0
    private var isMonitoring = false
    private var permissionObserver: NSObjectProtocol?
    private var appActiveObserver: NSObjectProtocol?
    
    deinit {
        stop()
    }
    
    private var permissionCheckTimer: Timer?
    
    func start() {
        guard !isMonitoring else { return }
        
        if tryCreateEventTap() {
            stopPermissionCheck()
        } else {
            startPermissionCheck()
        }
    }
    
    private func tryCreateEventTap() -> Bool {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                guard let userInfo = userInfo else {
                    return Unmanaged.passUnretained(event)
                }
                let monitor = Unmanaged<SequenceKeyMonitor>.fromOpaque(userInfo).takeUnretainedValue()
                monitor.handleCGEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        )
        
        guard let tap = eventTap else { return false }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isMonitoring = true
        return true
    }
    
    private func startPermissionCheck() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isMonitoring else {
                self?.stopPermissionCheck()
                return
            }
            
            if AXIsProcessTrusted() && self.tryCreateEventTap() {
                self.stopPermissionCheck()
            }
        }
    }
    
    private func stopPermissionCheck() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
        removeObservers()
    }
    
    private func removeObservers() {
        if let observer = permissionObserver {
            NotificationCenter.default.removeObserver(observer)
            permissionObserver = nil
        }
        if let observer = appActiveObserver {
            NotificationCenter.default.removeObserver(observer)
            appActiveObserver = nil
        }
    }
    
    func stop() {
        stopPermissionCheck()
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        cmdAPressedTime = nil
        isMonitoring = false
    }
    
    private func handleCGEvent(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        let hasCmd = flags.contains(.maskCommand)
        let noShift = !flags.contains(.maskShift)
        let noCtrl = !flags.contains(.maskControl)
        let noOpt = !flags.contains(.maskAlternate)
        let hasOnlyCmd = hasCmd && noShift && noCtrl && noOpt
        
        // keyCode 0 = A, keyCode 15 = R
        if keyCode == 0 && hasOnlyCmd {
            cmdAPressedTime = Date()
            return
        }
        
        if keyCode == 15 && hasOnlyCmd {
            if let cmdATime = cmdAPressedTime {
                let elapsed = Date().timeIntervalSince(cmdATime)
                if elapsed <= sequenceTimeout {
                    cmdAPressedTime = nil
                    DispatchQueue.main.async { [weak self] in
                        self?.onTranslateTrigger?()
                    }
                    return
                }
            }
        }
        
        if !hasCmd {
            cmdAPressedTime = nil
        }
    }
}
