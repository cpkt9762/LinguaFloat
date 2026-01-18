import XCTest
@testable import LinguaFloat

final class LanguageDetectorTests: XCTestCase {
    var detector: LanguageDetector!
    
    override func setUp() {
        super.setUp()
        detector = LanguageDetector()
    }
    
    override func tearDown() {
        detector = nil
        super.tearDown()
    }
    
    func testDetectEnglish() {
        let result = detector.detect("Hello, how are you today?")
        XCTAssertEqual(result, "en")
    }
    
    func testDetectSimplifiedChinese() {
        let result = detector.detect("你好，今天天气怎么样？")
        XCTAssertTrue(result == "zh-Hans" || result == "zh-CN")
    }
    
    func testDetectJapanese() {
        let result = detector.detect("こんにちは、元気ですか？")
        XCTAssertEqual(result, "ja")
    }
    
    func testDetectKorean() {
        let result = detector.detect("안녕하세요, 오늘 날씨가 어때요?")
        XCTAssertEqual(result, "ko")
    }
    
    func testDetectEmptyString() {
        let result = detector.detect("")
        XCTAssertNil(result)
    }
    
    func testDetectMixedContent() {
        let result = detector.detect("Hello 你好 World")
        XCTAssertNotNil(result)
    }
    
    func testIsChinese() {
        XCTAssertTrue(detector.isChinese("zh-Hans"))
        XCTAssertTrue(detector.isChinese("zh-CN"))
        XCTAssertTrue(detector.isChinese("zh-Hant"))
        XCTAssertTrue(detector.isChinese("zh-TW"))
        XCTAssertFalse(detector.isChinese("en"))
        XCTAssertFalse(detector.isChinese("ja"))
    }
}
