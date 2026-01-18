import Foundation
import SwiftUI

enum QuickTranslateDirection: Int {
    case chineseToEnglish = 0
    case englishToChinese = 1
    
    var sourceLanguage: String {
        switch self {
        case .chineseToEnglish: return "zh-CN"
        case .englishToChinese: return "en"
        }
    }
    
    var targetLanguage: String {
        switch self {
        case .chineseToEnglish: return "en"
        case .englishToChinese: return "zh-CN"
        }
    }
}

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    @AppStorage("smartDetection") var smartDetection = true
    @AppStorage("defaultTargetLanguage") var defaultTargetLanguage = "zh-CN"
    @AppStorage("chineseToLanguage") var chineseToLanguage = "en"
    @AppStorage("autoCopyOCR") var autoCopyOCR = false
    @AppStorage("autoLaunch") var autoLaunch = false
    @AppStorage("showInDock") var showInDock = false
    @AppStorage("quickTranslateDirection") var quickTranslateDirectionRaw = 0
    
    var quickTranslateDirection: QuickTranslateDirection {
        get { QuickTranslateDirection(rawValue: quickTranslateDirectionRaw) ?? .chineseToEnglish }
        set { quickTranslateDirectionRaw = newValue.rawValue }
    }
    
    private init() {}
    
    func getTargetLanguage(for detectedLanguage: String?) -> String {
        guard smartDetection else {
            return defaultTargetLanguage
        }
        
        if detectedLanguage == "zh-CN" || detectedLanguage == "zh" {
            return chineseToLanguage
        }
        
        return defaultTargetLanguage
    }
}
