import XCTest
@testable import LinguaFloat

final class ClipboardManagerTests: XCTestCase {
    var manager: ClipboardManager!
    
    override func setUp() {
        super.setUp()
        manager = ClipboardManager.shared
    }
    
    func testSaveAndRestoreClipboard() {
        let testString = "Test clipboard content \(UUID().uuidString)"
        
        manager.saveCurrentClipboard()
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(testString, forType: .string)
        
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), testString)
        
        manager.restoreClipboard()
    }
    
    func testCopyToClipboard() {
        let testString = "Copy test \(UUID().uuidString)"
        
        manager.copy(testString)
        
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), testString)
    }
    
    func testGetClipboardContent() {
        let testString = "Get test \(UUID().uuidString)"
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(testString, forType: .string)
        
        let content = manager.getCurrentContent()
        
        XCTAssertEqual(content, testString)
    }
}
