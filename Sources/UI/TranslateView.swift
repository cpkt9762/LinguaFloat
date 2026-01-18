import SwiftUI

struct TranslateView: View {
    @ObservedObject private var translationService = TranslationService.shared
    @State private var sourceText: String = ""
    
    private var trimmedSourceText: String {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var translatedText: String {
        translationService.lastResult?.translatedText ?? ""
    }
    
    private var errorMessage: String? {
        translationService.lastError?.localizedDescription
    }
    
    var onClose: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: {
                    onClose?()
                    FloatingPanelController.shared.hide()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("关闭")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("原文")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $sourceText)
                    .font(.body)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
            }
            
            HStack {
                Spacer()
                Button(action: performTranslation) {
                    if translationService.isTranslating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("翻译")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedSourceText.isEmpty || translationService.isTranslating)
                
                Button("从剪贴板粘贴") {
                    if let text = NSPasteboard.general.string(forType: .string) {
                        sourceText = text
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("译文")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if !translatedText.isEmpty {
                        Button("复制") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(translatedText, forType: .string)
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                } else {
                    Text(translatedText.isEmpty ? "翻译结果将显示在这里" : translatedText)
                        .font(.body)
                        .foregroundStyle(translatedText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 320, minHeight: 360)
        .onReceive(translationService.$lastResult) { result in
            if let result = result, sourceText.isEmpty {
                sourceText = result.originalText
            }
        }
    }
    
    private func performTranslation() {
        guard !trimmedSourceText.isEmpty else { return }
        
        Task {
            await translationService.translate(text: sourceText, sourceType: .manual)
        }
    }
}

#Preview {
    TranslateView()
}
