import Foundation
import SwiftData

@MainActor
final class HistoryService: ObservableObject {
    static let shared = HistoryService()
    
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    
    @Published var recentHistory: [TranslationHistory] = []
    @Published var favorites: [TranslationHistory] = []
    
    private init() {
        setupContainer()
    }
    
    private func setupContainer() {
        do {
            let schema = Schema([TranslationHistory.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer?.mainContext
        } catch {
            print("Failed to setup SwiftData container: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    func save(_ history: TranslationHistory) {
        guard let context = modelContext else { return }
        context.insert(history)
        try? context.save()
        refreshRecentHistory()
    }
    
    func saveFromResponse(_ response: TranslationResponse, sourceType: TranslationHistory.SourceType = .selection) {
        let history = TranslationHistory(
            originalText: response.originalText,
            translatedText: response.translatedText,
            detectedLanguage: response.detectedLanguage,
            provider: response.provider,
            sourceType: sourceType
        )
        save(history)
    }
    
    func delete(_ history: TranslationHistory) {
        guard let context = modelContext else { return }
        context.delete(history)
        try? context.save()
        refreshRecentHistory()
        refreshFavorites()
    }
    
    func deleteAll() {
        guard let context = modelContext else { return }
        do {
            try context.delete(model: TranslationHistory.self)
            try context.save()
            recentHistory = []
            favorites = []
        } catch {
            print("Failed to delete all history: \(error)")
        }
    }
    
    func toggleFavorite(_ history: TranslationHistory) {
        history.isFavorite.toggle()
        try? modelContext?.save()
        refreshFavorites()
    }
    
    // MARK: - Query Operations
    
    func refreshRecentHistory(limit: Int = 50) {
        guard let context = modelContext else { return }
        
        var descriptor = FetchDescriptor<TranslationHistory>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            recentHistory = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch recent history: \(error)")
        }
    }
    
    func refreshFavorites() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<TranslationHistory>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            favorites = try context.fetch(descriptor)
        } catch {
            print("Failed to fetch favorites: \(error)")
        }
    }
    
    func search(query: String, limit: Int = 100) -> [TranslationHistory] {
        guard let context = modelContext, !query.isEmpty else { return [] }
        
        let lowercaseQuery = query.lowercased()
        var descriptor = FetchDescriptor<TranslationHistory>(
            predicate: #Predicate { history in
                history.originalText.localizedStandardContains(lowercaseQuery) ||
                history.translatedText.localizedStandardContains(lowercaseQuery)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to search history: \(error)")
            return []
        }
    }
    
    func filter(
        sourceType: TranslationHistory.SourceType? = nil,
        provider: String? = nil,
        fromDate: Date? = nil,
        toDate: Date? = nil
    ) -> [TranslationHistory] {
        guard let context = modelContext else { return [] }
        
        var descriptor = FetchDescriptor<TranslationHistory>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            var results = try context.fetch(descriptor)
            
            if let sourceType = sourceType {
                results = results.filter { $0.sourceType == sourceType }
            }
            if let provider = provider {
                results = results.filter { $0.provider == provider }
            }
            if let fromDate = fromDate {
                results = results.filter { $0.createdAt >= fromDate }
            }
            if let toDate = toDate {
                results = results.filter { $0.createdAt <= toDate }
            }
            
            return results
        } catch {
            print("Failed to filter history: \(error)")
            return []
        }
    }
    
    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let exportItems = recentHistory.map { history in
            ExportItem(
                originalText: history.originalText,
                translatedText: history.translatedText,
                sourceLanguage: history.sourceLanguage,
                targetLanguage: history.targetLanguage,
                provider: history.provider,
                isFavorite: history.isFavorite,
                createdAt: history.createdAt,
                sourceType: history.sourceType.rawValue
            )
        }
        
        return try? encoder.encode(exportItems)
    }
}

private struct ExportItem: Codable {
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let provider: String
    let isFavorite: Bool
    let createdAt: Date
    let sourceType: String
}
