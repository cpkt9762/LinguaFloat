import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {
    private var trackingArea: NSTrackingArea?
    
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.contentView = contentView
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.animationBehavior = .utilityWindow
    }
    
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class FloatingPanelController {
    static let shared = FloatingPanelController()
    
    private var panel: FloatingPanel?
    private var dismissTimer: Timer?
    private var isMouseInside = false
    
    var autoDismissDelay: TimeInterval = 0
    var onDismiss: (() -> Void)?
    
    private init() {}
    
    func show<Content: View>(
        content: Content,
        near point: NSPoint? = nil,
        animated: Bool = true,
        autoDismiss: TimeInterval = 0
    ) {
        let wrappedContent = content
            .background(VisualEffectView())
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
        
        let hostingView = NSHostingView(rootView: wrappedContent)
        
        if panel == nil {
            panel = FloatingPanel(contentView: hostingView)
            setupGestureRecognizers()
        } else {
            panel?.contentView = hostingView
        }
        
        guard let panel = panel else { return }
        
        hostingView.setFrameSize(hostingView.fittingSize)
        panel.setContentSize(hostingView.fittingSize)
        
        if let point = point {
            positionNear(point: point)
        } else if let mouseLocation = NSEvent.mouseLocation as NSPoint? {
            positionNear(point: mouseLocation)
        }
        
        if animated {
            showWithAnimation()
        } else {
            panel.orderFrontRegardless()
            panel.makeKey()
        }
        
        autoDismissDelay = autoDismiss
        if autoDismiss > 0 {
            startAutoDismissTimer()
        }
    }
    
    func hide(animated: Bool = true) {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        if animated {
            hideWithAnimation()
        } else {
            panel?.orderOut(nil)
            onDismiss?()
        }
    }
    
    func toggle<Content: View>(content: Content, near point: NSPoint? = nil) {
        if panel?.isVisible == true {
            hide()
        } else {
            show(content: content, near: point)
        }
    }
    
    // MARK: - Animation
    
    private func showWithAnimation() {
        guard let panel = panel else { return }
        
        panel.alphaValue = 0
        
        let originalFrame = panel.frame
        let startFrame = NSRect(
            x: originalFrame.origin.x,
            y: originalFrame.origin.y - 10,
            width: originalFrame.width,
            height: originalFrame.height
        )
        panel.setFrame(startFrame, display: false)
        
        panel.orderFrontRegardless()
        panel.makeKey()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            panel.animator().alphaValue = 1
            panel.animator().setFrame(originalFrame, display: true)
        }
    }
    
    private func hideWithAnimation() {
        guard let panel = panel else { return }
        
        let currentFrame = panel.frame
        let endFrame = NSRect(
            x: currentFrame.origin.x,
            y: currentFrame.origin.y - 10,
            width: currentFrame.width,
            height: currentFrame.height
        )
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            panel.animator().alphaValue = 0
            panel.animator().setFrame(endFrame, display: true)
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            panel.alphaValue = 1
            self?.onDismiss?()
        })
    }
    
    // MARK: - Positioning
    
    private func positionNear(point: NSPoint) {
        guard let panel = panel, let screen = NSScreen.main else { return }
        
        let panelSize = panel.frame.size
        let screenFrame = screen.visibleFrame
        
        var x = point.x - panelSize.width / 2
        var y = point.y + 20
        
        if x < screenFrame.minX {
            x = screenFrame.minX + 10
        } else if x + panelSize.width > screenFrame.maxX {
            x = screenFrame.maxX - panelSize.width - 10
        }
        
        if y + panelSize.height > screenFrame.maxY {
            y = point.y - panelSize.height - 20
        }
        
        if y < screenFrame.minY {
            y = screenFrame.minY + 10
        }
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    // MARK: - Gestures
    
    private func setupGestureRecognizers() {
        guard let panel = panel, let contentView = panel.contentView else { return }
        
        let swipeDown = NSPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        contentView.addGestureRecognizer(swipeDown)
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.hide()
                return nil
            }
            return event
        }
    }
    
    @objc private func handleSwipe(_ gesture: NSPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
        switch gesture.state {
        case .changed:
            if translation.y < -30 {
                hide()
            }
        default:
            break
        }
    }
    
    // MARK: - Auto Dismiss
    
    private func startAutoDismissTimer() {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissDelay, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }
    
    func pauseAutoDismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
    
    func resumeAutoDismiss() {
        if autoDismissDelay > 0 {
            startAutoDismissTimer()
        }
    }
}

// MARK: - Visual Effect View

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - SwiftUI Animation Extensions

struct FadeSlideModifier: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : 10)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
}

struct ScaleModifier: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPresented ? 1 : 0.95)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPresented)
    }
}

extension View {
    func fadeSlide(isPresented: Bool) -> some View {
        modifier(FadeSlideModifier(isPresented: isPresented))
    }
    
    func scaleAppear(isPresented: Bool) -> some View {
        modifier(ScaleModifier(isPresented: isPresented))
    }
}

// MARK: - Loading Animation

struct LoadingDots: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1)
            .animation(
                .easeInOut(duration: 1)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

extension View {
    func pulse() -> some View {
        modifier(PulseAnimation())
    }
}
