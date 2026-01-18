import SwiftUI
import WebKit

struct GoogleTranslateWebView: NSViewRepresentable {
    let text: String
    let sourceLanguage: String
    let targetLanguage: String
    
    init(text: String, sourceLanguage: String = "auto", targetLanguage: String = "zh-CN") {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        loadTranslation(webView: webView)
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        loadTranslation(webView: webView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func loadTranslation(webView: WKWebView) {
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.google.com/#view=home&op=translate&sl=\(sourceLanguage)&tl=\(targetLanguage)&text=\(encodedText)") else {
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView provisional navigation failed: \(error.localizedDescription)")
        }
    }
}

struct GoogleTranslatePopoverView: View {
    let text: String
    let onClose: () -> Void
    
    @AppStorage("defaultTargetLanguage") private var targetLanguage = "zh-CN"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Google 翻译")
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
            
            GoogleTranslateWebView(text: text, targetLanguage: targetLanguage)
                .frame(minWidth: 400, minHeight: 300)
        }
        .frame(width: 450, height: 400)
    }
}

#Preview {
    GoogleTranslatePopoverView(text: "Hello, world!") {}
}
