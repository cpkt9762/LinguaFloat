import Foundation
import Vision
import AppKit
import ScreenCaptureKit

enum OCRError: LocalizedError {
    case screenshotFailed
    case noTextFound
    case recognitionFailed(String)
    case permissionDenied
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .screenshotFailed:
            return "截图失败"
        case .noTextFound:
            return "未识别到文字"
        case .recognitionFailed(let message):
            return "识别失败: \(message)"
        case .permissionDenied:
            return "无截图权限，请在系统设置中授权"
        case .cancelled:
            return "操作已取消"
        }
    }
    
    var isCancelled: Bool {
        if case .cancelled = self { return true }
        return false
    }
}

struct OCRResult {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

@MainActor
final class OCRService: ObservableObject {
    static let shared = OCRService()
    
    @Published var isCapturing = false
    @Published var isRecognizing = false
    @Published var lastResults: [OCRResult] = []
    @Published var lastError: OCRError?
    
    private var overlayWindow: NSWindow?
    private var selectionView: SelectionOverlayView?
    
    private init() {}
    
    func captureAndRecognize() async throws -> String {
        isCapturing = true
        lastError = nil
        
        defer { isCapturing = false }
        
        let (selectedRect, targetScreen) = try await showSelectionOverlay()
        let image = try await captureScreen(rect: selectedRect, screen: targetScreen)
        return try await recognizeText(in: image)
    }
    
    func recognizeText(in image: NSImage) async throws -> String {
        isRecognizing = true
        lastError = nil
        
        defer { isRecognizing = false }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.recognitionFailed("无法转换图像")
        }
        
        return try await performOCR(on: cgImage)
    }
    
    private func showSelectionOverlay() async throws -> (CGRect, NSScreen) {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: OCRError.cancelled)
                return
            }
            self.createOverlayWindow { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createOverlayWindow(completion: @escaping (Result<(CGRect, NSScreen), OCRError>) -> Void) {
        let screens = NSScreen.screens
        var unionFrame = CGRect.zero
        for screen in screens {
            unionFrame = unionFrame.union(screen.frame)
        }
        
        let window = NSWindow(
            contentRect: unionFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.overlayWindow = window
        
        let selectionView = SelectionOverlayView(frame: unionFrame)
        self.selectionView = selectionView
        
        selectionView.onSelectionComplete = { [weak self] rect, screen in
            let validSelection = rect.width > 10 && rect.height > 10
            self?.dismissOverlay()
            if validSelection {
                completion(.success((rect, screen)))
            } else {
                completion(.failure(.cancelled))
            }
        }
        selectionView.onCancel = { [weak self] in
            self?.dismissOverlay()
            completion(.failure(.cancelled))
        }
        
        window.contentView = selectionView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeFirstResponder(selectionView)
        
        NSCursor.crosshair.set()
    }
    
    private func dismissOverlay() {
        NSCursor.arrow.set()
        selectionView?.onSelectionComplete = nil
        selectionView?.onCancel = nil
        selectionView = nil
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
    
    private func captureScreen(rect: CGRect, screen: NSScreen) async throws -> NSImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let display = content.displays.first(where: { $0.displayID == screenID }) else {
            throw OCRError.screenshotFailed
        }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        let scaleFactor = screen.backingScaleFactor
        
        let config = SCStreamConfiguration()
        config.sourceRect = rect
        config.width = Int(rect.width * scaleFactor)
        config.height = Int(rect.height * scaleFactor)
        config.scalesToFit = false
        config.showsCursor = false
        
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
        
        let size = NSSize(width: CGFloat(image.width) / scaleFactor, height: CGFloat(image.height) / scaleFactor)
        return NSImage(cgImage: image, size: size)
    }
    
    private func performOCR(on cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            var hasResumed = false
            
            let request = VNRecognizeTextRequest { request, error in
                guard !hasResumed else { return }
                hasResumed = true
                
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                var results: [OCRResult] = []
                var fullText = ""
                
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    
                    let result = OCRResult(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                    results.append(result)
                    
                    if !fullText.isEmpty {
                        fullText += "\n"
                    }
                    fullText += topCandidate.string
                }
                
                if fullText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    let finalResults = results
                    Task { @MainActor in
                        self?.lastResults = finalResults
                    }
                    continuation.resume(returning: fullText)
                }
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "ja", "ko"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }
}

final class SelectionOverlayView: NSView {
    var onSelectionComplete: ((CGRect, NSScreen) -> Void)?
    var onCancel: (() -> Void)?
    
    private var startPoint: NSPoint?
    private var currentRect: CGRect = .zero
    private var selectionLayer: CAShapeLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        wantsLayer = true
        
        let layer = CAShapeLayer()
        layer.fillColor = NSColor.systemBlue.withAlphaComponent(0.2).cgColor
        layer.strokeColor = NSColor.systemBlue.cgColor
        layer.lineWidth = 2
        layer.lineDashPattern = [5, 3]
        self.layer?.addSublayer(layer)
        selectionLayer = layer
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let width = abs(current.x - start.x)
        let height = abs(current.y - start.y)
        
        currentRect = CGRect(x: minX, y: minY, width: width, height: height)
        updateSelectionLayer()
    }
    
    override func mouseUp(with event: NSEvent) {
        let (screenRect, targetScreen) = convertToScreenCoordinates(currentRect)
        onSelectionComplete?(screenRect, targetScreen)
    }
    
    private func updateSelectionLayer() {
        let path = CGPath(rect: currentRect, transform: nil)
        selectionLayer?.path = path
    }
    
    private func convertToScreenCoordinates(_ rect: CGRect) -> (CGRect, NSScreen) {
        guard let window = window else {
            return (rect, NSScreen.main ?? NSScreen.screens[0])
        }
        
        let windowRect = convert(rect, to: nil)
        let screenRect = window.convertToScreen(windowRect)
        
        let screenWithAreas: [(screen: NSScreen, area: CGFloat)] = NSScreen.screens.map { screen in
            let intersection = screen.frame.intersection(screenRect)
            return (screen: screen, area: intersection.width * intersection.height)
        }
        let targetScreen = screenWithAreas
            .filter { $0.area > 0 }
            .max { $0.area < $1.area }?
            .screen ?? NSScreen.main ?? NSScreen.screens[0]
        
        let flippedY = targetScreen.frame.maxY - screenRect.maxY
        
        let localRect = CGRect(
            x: screenRect.origin.x - targetScreen.frame.origin.x,
            y: flippedY,
            width: screenRect.width,
            height: screenRect.height
        )
        
        return (localRect, targetScreen)
    }
}


