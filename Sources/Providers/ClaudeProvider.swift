import Foundation

final class ClaudeProvider: TranslationProvider {
    let name = "Claude"
    let capabilities: ProviderCapabilities = [.languageDetection, .streaming]
    
    private let apiKey: String
    private let model: String
    private let baseURL: String
    
    init(apiKey: String, model: String = "claude-3-haiku-20240307", baseURL: String = "https://api.anthropic.com/v1") {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }
    
    func translate(_ request: TranslationRequest) async throws -> TranslationResponse {
        guard !apiKey.isEmpty else {
            throw TranslationError.authenticationFailed
        }
        
        let systemPrompt = buildSystemPrompt(targetLanguage: request.targetLanguage)
        let url = URL(string: "\(baseURL)/messages")!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": request.text]
            ]
        ]
        
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.unknown("Invalid response")
        }
        
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw TranslationError.authenticationFailed
        case 429:
            throw TranslationError.rateLimited
        default:
            throw TranslationError.unknown("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw TranslationError.parseError
        }
        
        return TranslationResponse(
            originalText: request.text,
            translatedText: text.trimmingCharacters(in: .whitespacesAndNewlines),
            detectedLanguage: nil,
            provider: name
        )
    }
    
    private func buildSystemPrompt(targetLanguage: String) -> String {
        let languageName = languageCodeToName(targetLanguage)
        return """
        You are a professional translator. Translate the user's text to \(languageName).
        Rules:
        - Only output the translated text, no explanations
        - Preserve the original formatting and line breaks
        - Keep technical terms, proper nouns, and code unchanged
        - Maintain the original tone and style
        """
    }
    
    private func languageCodeToName(_ code: String) -> String {
        let map = [
            "zh-CN": "Simplified Chinese",
            "zh-TW": "Traditional Chinese",
            "en": "English",
            "ja": "Japanese",
            "ko": "Korean",
            "fr": "French",
            "de": "German",
            "es": "Spanish"
        ]
        return map[code] ?? code
    }
}
