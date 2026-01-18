import Foundation

enum AITool: String, CaseIterable {
    case explain = "解释"
    case rewrite = "重写"
    case grammar = "语法检查"
    case summarize = "总结"
    case define = "定义"
    
    var systemPrompt: String {
        switch self {
        case .explain:
            return "Please explain the following text in simple terms. Be concise and clear."
        case .rewrite:
            return "Please rewrite the following text to improve clarity and readability while preserving the meaning."
        case .grammar:
            return "Please check the grammar of the following text and provide corrections with explanations."
        case .summarize:
            return "Please provide a concise summary of the following text."
        case .define:
            return "Please provide a definition and explanation of the following word or phrase."
        }
    }
    
    var icon: String {
        switch self {
        case .explain: return "questionmark.circle"
        case .rewrite: return "pencil.line"
        case .grammar: return "checkmark.circle"
        case .summarize: return "text.alignleft"
        case .define: return "book"
        }
    }
}

final class AIToolService {
    static let shared = AIToolService()
    
    private var currentProvider: (any TranslationProvider)?
    
    private init() {}
    
    func setProvider(_ provider: any TranslationProvider) {
        currentProvider = provider
    }
    
    func execute(tool: AITool, text: String, targetLanguage: String = "zh-CN") async throws -> String {
        guard let provider = currentProvider else {
            throw TranslationError.unknown("No provider configured")
        }
        
        let request = TranslationRequest(
            text: "\(tool.systemPrompt)\n\nText: \(text)",
            sourceLanguage: "auto",
            targetLanguage: targetLanguage
        )
        
        let response = try await provider.translate(request)
        return response.translatedText
    }
}
