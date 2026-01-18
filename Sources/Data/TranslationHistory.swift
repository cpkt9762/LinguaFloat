import Foundation
import SwiftData

@Model
final class TranslationHistory {
    var id: UUID
    var originalText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var detectedLanguage: String?
    var provider: String
    var isFavorite: Bool
    var createdAt: Date
    var sourceType: SourceType
    
    enum SourceType: String, Codable {
        case selection
        case ocr
        case manual
    }
    
    init(
        originalText: String,
        translatedText: String,
        sourceLanguage: String = "auto",
        targetLanguage: String = "zh-CN",
        detectedLanguage: String? = nil,
        provider: String,
        sourceType: SourceType = .selection
    ) {
        self.id = UUID()
        self.originalText = originalText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.detectedLanguage = detectedLanguage
        self.provider = provider
        self.isFavorite = false
        self.createdAt = Date()
        self.sourceType = sourceType
    }
}

extension TranslationHistory {
    static func from(_ response: TranslationResponse, sourceType: SourceType = .selection) -> TranslationHistory {
        TranslationHistory(
            originalText: response.originalText,
            translatedText: response.translatedText,
            detectedLanguage: response.detectedLanguage,
            provider: response.provider,
            sourceType: sourceType
        )
    }
}
