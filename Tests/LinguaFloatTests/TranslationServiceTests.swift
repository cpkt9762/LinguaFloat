import XCTest
@testable import LinguaFloat

final class TranslationServiceTests: XCTestCase {
    
    func testTranslationRequestInitialization() {
        let request = TranslationRequest(
            text: "Hello",
            sourceLanguage: "en",
            targetLanguage: "zh-CN"
        )
        
        XCTAssertEqual(request.text, "Hello")
        XCTAssertEqual(request.sourceLanguage, "en")
        XCTAssertEqual(request.targetLanguage, "zh-CN")
    }
    
    func testTranslationRequestDefaults() {
        let request = TranslationRequest(text: "Test")
        
        XCTAssertEqual(request.sourceLanguage, "auto")
        XCTAssertEqual(request.targetLanguage, "zh-CN")
    }
    
    func testTranslationResponseInitialization() {
        let response = TranslationResponse(
            originalText: "Hello",
            translatedText: "你好",
            detectedLanguage: "en",
            provider: "Test Provider"
        )
        
        XCTAssertEqual(response.originalText, "Hello")
        XCTAssertEqual(response.translatedText, "你好")
        XCTAssertEqual(response.detectedLanguage, "en")
        XCTAssertEqual(response.provider, "Test Provider")
    }
    
    func testProviderCapabilities() {
        let caps: ProviderCapabilities = [.languageDetection, .streaming]
        
        XCTAssertTrue(caps.contains(.languageDetection))
        XCTAssertTrue(caps.contains(.streaming))
        XCTAssertFalse(caps.contains(.glossary))
        XCTAssertFalse(caps.contains(.batchTranslation))
    }
    
    func testTranslationErrorDescriptions() {
        XCTAssertNotNil(TranslationError.networkUnavailable.errorDescription)
        XCTAssertNotNil(TranslationError.authenticationFailed.errorDescription)
        XCTAssertNotNil(TranslationError.rateLimited.errorDescription)
        XCTAssertNotNil(TranslationError.contentTooLong.errorDescription)
        XCTAssertNotNil(TranslationError.unsupportedLanguage.errorDescription)
        XCTAssertNotNil(TranslationError.parseError.errorDescription)
        XCTAssertNotNil(TranslationError.unknown("test").errorDescription)
    }
}
