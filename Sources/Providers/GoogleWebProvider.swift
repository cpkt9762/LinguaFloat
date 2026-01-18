import Foundation

final class GoogleWebProvider: TranslationProvider {
    let name = "Google Translate (Web)"
    let capabilities: ProviderCapabilities = [.languageDetection]
    
    private let baseURL = "https://translate.googleapis.com/translate_a/single"
    
    func translate(_ request: TranslationRequest) async throws -> TranslationResponse {
        guard let url = buildAPIURL(
            text: request.text,
            sourceLanguage: request.sourceLanguage,
            targetLanguage: request.targetLanguage
        ) else {
            throw TranslationError.unknown("无法构建请求 URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranslationError.networkUnavailable
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 429 {
                    throw TranslationError.rateLimited
                }
                throw TranslationError.unknown("HTTP 错误: \(httpResponse.statusCode)")
            }
            
            return try parseResponse(data: data, originalText: request.text)
        } catch let error as TranslationError {
            throw error
        } catch {
            throw TranslationError.networkUnavailable
        }
    }
    
    private func buildAPIURL(text: String, sourceLanguage: String, targetLanguage: String) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "client", value: "gtx"),
            URLQueryItem(name: "sl", value: sourceLanguage),
            URLQueryItem(name: "tl", value: targetLanguage),
            URLQueryItem(name: "dt", value: "t"),
            URLQueryItem(name: "dt", value: "bd"),
            URLQueryItem(name: "dj", value: "1"),
            URLQueryItem(name: "q", value: text)
        ]
        return components?.url
    }
    
    private func parseResponse(data: Data, originalText: String) throws -> TranslationResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TranslationError.parseError
        }
        
        var translatedText = ""
        var detectedLanguage: String?
        
        if let sentences = json["sentences"] as? [[String: Any]] {
            for sentence in sentences {
                if let trans = sentence["trans"] as? String {
                    translatedText += trans
                }
            }
        }
        
        if let src = json["src"] as? String {
            detectedLanguage = src
        }
        
        if translatedText.isEmpty {
            throw TranslationError.parseError
        }
        
        return TranslationResponse(
            originalText: originalText,
            translatedText: translatedText,
            detectedLanguage: detectedLanguage,
            provider: name
        )
    }
}
