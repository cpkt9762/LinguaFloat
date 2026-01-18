import XCTest
@testable import LinguaFloat

final class HistoryServiceTests: XCTestCase {
    
    func testTranslationHistoryInitialization() {
        let history = TranslationHistory(
            originalText: "Hello",
            translatedText: "你好",
            sourceLanguage: "en",
            targetLanguage: "zh-CN",
            detectedLanguage: "en",
            provider: "Google",
            sourceType: .selection
        )
        
        XCTAssertEqual(history.originalText, "Hello")
        XCTAssertEqual(history.translatedText, "你好")
        XCTAssertEqual(history.sourceLanguage, "en")
        XCTAssertEqual(history.targetLanguage, "zh-CN")
        XCTAssertEqual(history.detectedLanguage, "en")
        XCTAssertEqual(history.provider, "Google")
        XCTAssertEqual(history.sourceType, .selection)
        XCTAssertFalse(history.isFavorite)
        XCTAssertNotNil(history.id)
        XCTAssertNotNil(history.createdAt)
    }
    
    func testTranslationHistoryDefaults() {
        let history = TranslationHistory(
            originalText: "Test",
            translatedText: "测试",
            provider: "Test"
        )
        
        XCTAssertEqual(history.sourceLanguage, "auto")
        XCTAssertEqual(history.targetLanguage, "zh-CN")
        XCTAssertNil(history.detectedLanguage)
        XCTAssertEqual(history.sourceType, .selection)
    }
    
    func testSourceTypeRawValues() {
        XCTAssertEqual(TranslationHistory.SourceType.selection.rawValue, "selection")
        XCTAssertEqual(TranslationHistory.SourceType.ocr.rawValue, "ocr")
        XCTAssertEqual(TranslationHistory.SourceType.manual.rawValue, "manual")
    }
}
