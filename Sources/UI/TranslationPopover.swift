import SwiftUI
import AppKit

// MARK: - States

enum TranslationPopoverState {
    case loading
    case success(result: TranslationResponse)
    case error(message: String)
    case noTranslation(reason: String)
}

// MARK: - Main View

struct TranslationPopoverView: View {
    @ObservedObject var translationService: TranslationService
    var onClose: (() -> Void)?
    var onRetry: (() -> Void)?
    
    private var currentState: TranslationPopoverState {
        if translationService.isTranslating {
            return .loading
        }
        
        if let error = translationService.lastError {
            return .error(message: error.localizedDescription)
        }
        
        if let result = translationService.lastResult {
            let isIdentical = result.originalText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
                            result.translatedText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            if isIdentical {
                return .noTranslation(reason: "选中文本无需翻译。")
            }
            return .success(result: result)
        }
        
        // Default to loading if nothing is set yet but view is shown
        return .loading
    }
    
    var body: some View {
        ZStack {
            // Background
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
            
            // Content
            Group {
                switch currentState {
                case .loading:
                    LoadingStateView(onClose: onClose)
                case .success(let result):
                    SuccessStateView(result: result, onClose: onClose, onRetry: onRetry)
                case .error(let message):
                    ErrorStateView(message: message, onClose: onClose, onRetry: onRetry)
                case .noTranslation(let reason):
                    NoTranslationStateView(reason: reason, onClose: onClose)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        .frame(minWidth: 280, maxWidth: 340)
        .fixedSize(horizontal: false, vertical: true) // Allow height to fit content
        .onTapGesture {
            // Handle tap on background if needed
        }
        // Handle ESC key to close - This is usually handled by the window/panel controller
        // but we can add an invisible button or similar if focus is here.
        // For now, relies on the parent FloatingPanel handling standard behaviors.
        .overlay(
            EmptyView()
        )
    }
}

// MARK: - State Subviews

struct LoadingStateView: View {
    var onClose: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .controlSize(.small)
                .frame(width: 16, height: 16)
            
            Text("翻译中...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            IconButton(iconName: "xmark") {
                onClose?()
            }
            .opacity(0.6)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
}

// 2. Success State
struct SuccessStateView: View {
    let result: TranslationResponse
    var onClose: (() -> Void)?
    var onRetry: (() -> Void)?
    
    @State private var isHoveringHeader = false
    @State private var isHoveringFooter = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(languagePairText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    IconButton(iconName: "doc.on.doc") {
                        copyToClipboard(result.translatedText)
                    }
                    .help("复制")
                    
                    IconButton(iconName: "pin") { }
                    .help("固定")
                    
                    IconButton(iconName: "ellipsis") { }
                    .help("更多")
                    
                    IconButton(iconName: "xmark") {
                        onClose?()
                    }
                    .help("关闭")
                }
                .opacity(isHoveringHeader ? 1 : 0.6)
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .onHover { hover in isHoveringHeader = hover }
            
            // Main Content
            Text(result.translatedText)
                .font(.system(size: 15))
                .lineSpacing(4)
                .textSelection(.enabled)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Bottom Action Bar
            HStack {
                HStack(spacing: 12) {
                    ActionButton(iconName: "speaker.wave.2") { }
                    ActionButton(iconName: "star") { }
                    ActionButton(iconName: "bubble.left") { }
                }
                
                Spacer()
                
                if let onRetry = onRetry {
                    Button(action: onRetry) {
                        HStack(spacing: 4) {
                            Text("重试")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { inside in
                        if inside { NSCursor.pointingHand.push() }
                        else { NSCursor.pop() }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .opacity(isHoveringFooter ? 1 : 0.5)
            .onHover { hover in isHoveringFooter = hover }
        }
    }
    
    private var languagePairText: String {
        let source = result.detectedLanguage?.uppercased() ?? "EN"
        return "\(source) → 中文"
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

struct ErrorStateView: View {
    let message: String
    var onClose: (() -> Void)?
    var onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                IconButton(iconName: "xmark") {
                    onClose?()
                }
                .opacity(0.6)
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("网络错误，请重试。")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                    
                    if !message.isEmpty && message != "网络错误，请重试。" {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("重试")
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            }
            
            Spacer().frame(height: 4)
        }
        .padding(.bottom, 12)
    }
}

struct NoTranslationStateView: View {
    let reason: String
    var onClose: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color(nsColor: .systemGray))
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("无需翻译")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            IconButton(iconName: "xmark") {
                onClose?()
            }
            .opacity(0.6)
        }
        .padding(16)
    }
}

// MARK: - Subcomponents

struct IconButton: View {
    let iconName: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(isHovering ? .primary : .secondary)
                .padding(4)
                .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onHover { hover in isHovering = hover }
    }
}

struct ActionButton: View {
    let iconName: String
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(isHovering ? .primary : .secondary)
                .padding(4)
                .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hover in isHovering = hover }
    }
}

// MARK: - Triple Space Hint

struct TripleSpaceHintView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "keyboard")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

struct TranslationPopoverView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TranslationPopoverView(translationService: makeService(translating: true))
                .previewDisplayName("Loading")
            
            TranslationPopoverView(translationService: makeService(result: TranslationResponse(originalText: "Hello", translatedText: "你好", detectedLanguage: "en", provider: "mock")))
                .previewDisplayName("Success")
            
            TranslationPopoverView(translationService: makeService(error: .networkUnavailable))
                .previewDisplayName("Error")
            
            TranslationPopoverView(translationService: makeService(result: TranslationResponse(originalText: "中文", translatedText: "中文", detectedLanguage: "zh", provider: "mock")))
                .previewDisplayName("No Translation")
        }
        .padding()
        .background(Color.gray)
    }
    
    static func makeService(translating: Bool = false, result: TranslationResponse? = nil, error: TranslationError? = nil) -> TranslationService {
        let service = TranslationService()
        service.isTranslating = translating
        service.lastResult = result
        service.lastError = error
        return service
    }
}
