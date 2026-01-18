import Foundation
import NaturalLanguage

final class LanguageDetector {
    static let shared = LanguageDetector()
    
    private init() {}
    
    func detect(text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        guard let language = recognizer.dominantLanguage else { return nil }
        
        return languageCodeMap[language] ?? language.rawValue
    }
    
    func getTargetLanguage(for sourceText: String) -> String {
        let settings = SettingsStore.shared
        
        guard settings.smartDetection else {
            return settings.defaultTargetLanguage
        }
        
        let detectedLanguage = detect(text: sourceText)
        
        if detectedLanguage == "zh-CN" || detectedLanguage == "zh" || detectedLanguage == "zh-Hans" {
            return settings.chineseToLanguage
        }
        
        return settings.defaultTargetLanguage
    }
    
    private let languageCodeMap: [NLLanguage: String] = [
        .simplifiedChinese: "zh-CN",
        .traditionalChinese: "zh-TW",
        .english: "en",
        .japanese: "ja",
        .korean: "ko",
        .french: "fr",
        .german: "de",
        .spanish: "es",
        .portuguese: "pt",
        .italian: "it",
        .russian: "ru",
        .arabic: "ar",
        .thai: "th",
        .vietnamese: "vi"
    ]
}
