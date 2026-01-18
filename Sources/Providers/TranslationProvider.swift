import Foundation

enum TranslationError: LocalizedError {
    case networkUnavailable
    case authenticationFailed
    case rateLimited
    case contentTooLong
    case unsupportedLanguage
    case parseError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "网络不可用，请检查网络连接"
        case .authenticationFailed:
            return "认证失败，请检查 API Key"
        case .rateLimited:
            return "请求过于频繁，请稍后重试"
        case .contentTooLong:
            return "内容过长，请缩短文本"
        case .unsupportedLanguage:
            return "不支持的语言"
        case .parseError:
            return "解析翻译结果失败"
        case .unknown(let message):
            return message
        }
    }
}

struct TranslationRequest {
    let text: String
    let sourceLanguage: String
    let targetLanguage: String
    
    init(text: String, sourceLanguage: String = "auto", targetLanguage: String = "zh-CN") {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }
}

struct TranslationResponse {
    let originalText: String
    let translatedText: String
    let detectedLanguage: String?
    let provider: String
}

struct ProviderCapabilities: OptionSet {
    let rawValue: Int
    
    static let languageDetection = ProviderCapabilities(rawValue: 1 << 0)
    static let streaming = ProviderCapabilities(rawValue: 1 << 1)
    static let glossary = ProviderCapabilities(rawValue: 1 << 2)
    static let batchTranslation = ProviderCapabilities(rawValue: 1 << 3)
}

protocol TranslationProvider {
    var name: String { get }
    var capabilities: ProviderCapabilities { get }
    
    func translate(_ request: TranslationRequest) async throws -> TranslationResponse
}
