import SwiftUI

struct CompareTranslationView: View {
    let originalText: String
    let results: [TranslationResult]
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("翻译对比")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("原文")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(originalText)
                            .font(.body)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                    }
                    
                    ForEach(results) { result in
                        TranslationResultCard(result: result)
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 500)
    }
}

struct TranslationResultCard: View {
    let result: TranslationResult
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.providerName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                
                Spacer()
                
                if result.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if let error = result.error {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else {
                    Button(action: copyToClipboard) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            if let error = result.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if result.isLoading {
                Text("翻译中...")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                Text(result.translatedText)
                    .font(.body)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(result.translatedText, forType: .string)
        isCopied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopied = false
        }
    }
}

struct TranslationResult: Identifiable {
    let id = UUID()
    let providerName: String
    var translatedText: String = ""
    var isLoading: Bool = true
    var error: String?
}
