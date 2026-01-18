import Foundation

@MainActor
final class TranslationService: ObservableObject {
    static let shared = TranslationService()
    
    @Published var isTranslating = false
    @Published var lastResult: TranslationResponse?
    @Published var lastError: TranslationError?
    
    private var currentProvider: any TranslationProvider
    private var cache = NSCache<NSString, CachedResponse>()
    private var currentTask: Task<Void, Never>?
    private var currentRequestId: UInt64 = 0
    
    private let maxCacheSize = 100
    
    init(provider: any TranslationProvider = GoogleWebProvider()) {
        self.currentProvider = provider
        cache.countLimit = maxCacheSize
    }
    
    func translate(
        text: String,
        sourceLanguage: String = "auto",
        targetLanguage: String = "zh-CN",
        sourceType: TranslationHistory.SourceType = .selection
    ) async {
        currentTask?.cancel()
        currentRequestId &+= 1
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            resetState()
            return
        }
        
        let cacheKey = "\(trimmedText)|\(sourceLanguage)|\(targetLanguage)" as NSString
        
        if let cached = cache.object(forKey: cacheKey) {
            lastResult = cached.response
            lastError = nil
            isTranslating = false
            currentTask = nil
            if SettingsStore.shared.autoSaveHistory {
                HistoryService.shared.saveFromResponse(cached.response, sourceType: sourceType)
            }
            return
        }
        
        let myRequestId = currentRequestId
        
        isTranslating = true
        lastError = nil
        
        let task = Task {
            defer {
                if myRequestId == currentRequestId {
                    isTranslating = false
                    currentTask = nil
                }
            }
            
            let request = TranslationRequest(
                text: trimmedText,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
            
            do {
                try Task.checkCancellation()
                let response = try await currentProvider.translate(request)
                
                try Task.checkCancellation()
                guard myRequestId == currentRequestId else { return }
                
                cache.setObject(CachedResponse(response: response), forKey: cacheKey)
                lastResult = response
                
                if SettingsStore.shared.autoSaveHistory {
                    HistoryService.shared.saveFromResponse(response, sourceType: sourceType)
                }
            } catch is CancellationError {
                return
            } catch let error as TranslationError {
                guard myRequestId == currentRequestId else { return }
                lastError = error
            } catch {
                guard myRequestId == currentRequestId else { return }
                lastError = .unknown(error.localizedDescription)
            }
        }
        
        currentTask = task
        await task.value
    }
    
    private func resetState() {
        currentRequestId &+= 1
        isTranslating = false
        lastResult = nil
        lastError = nil
        currentTask?.cancel()
        currentTask = nil
    }
    
    func cancelCurrentTranslation() {
        currentRequestId &+= 1
        currentTask?.cancel()
        currentTask = nil
        isTranslating = false
    }
    
    func switchProvider(_ provider: any TranslationProvider) {
        cancelCurrentTranslation()
        currentProvider = provider
        cache.removeAllObjects()
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

private final class CachedResponse: NSObject {
    let response: TranslationResponse
    let timestamp: Date
    
    init(response: TranslationResponse) {
        self.response = response
        self.timestamp = Date()
    }
}

extension SettingsStore {
    var autoSaveHistory: Bool {
        get { UserDefaults.standard.bool(forKey: "autoSaveHistory") }
        set { UserDefaults.standard.set(newValue, forKey: "autoSaveHistory") }
    }
}
