import SwiftUI
import SwiftData
import Combine

struct HistoryView: View {
    @ObservedObject var historyService = HistoryService.shared
    
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var selectedTab: HistoryTab = .all
    @State private var selectedSourceFilter: TranslationHistory.SourceType?
    @State private var selectedProviderFilter: String?
    @State private var showingExportSheet = false
    @State private var selectedHistory: TranslationHistory?
    
    private let searchDebouncer = PassthroughSubject<String, Never>()
    @State private var cancellables: Set<AnyCancellable>?
    
    enum HistoryTab: String, CaseIterable {
        case all = "全部"
        case favorites = "收藏"
    }
    
    var filteredHistory: [TranslationHistory] {
        let baseResults: [TranslationHistory] = selectedTab == .all
            ? historyService.recentHistory
            : historyService.favorites
        
        var results = baseResults
        
        if !debouncedSearchText.isEmpty {
            let query = debouncedSearchText.lowercased()
            results = results.filter {
                $0.originalText.localizedCaseInsensitiveContains(query) ||
                $0.translatedText.localizedCaseInsensitiveContains(query)
            }
        }
        
        if let sourceFilter = selectedSourceFilter {
            results = results.filter { $0.sourceType == sourceFilter }
        }
        
        if let providerFilter = selectedProviderFilter {
            results = results.filter { $0.provider == providerFilter }
        }
        
        return results
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            
            if filteredHistory.isEmpty {
                emptyStateView
            } else {
                historyListView
            }
        }
        .frame(minWidth: 400, minHeight: 500)
        .onAppear {
            historyService.refreshRecentHistory()
            historyService.refreshFavorites()
            setupSearchDebouncer()
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSheet(historyService: historyService)
        }
    }
    
    private func setupSearchDebouncer() {
        guard cancellables == nil else { return }
        var newCancellables = Set<AnyCancellable>()
        searchDebouncer
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { value in
                debouncedSearchText = value
            }
            .store(in: &newCancellables)
        cancellables = newCancellables
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("翻译历史")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingExportSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.borderless)
                .help("导出历史")
                
                Menu {
                    Button("清空全部历史", role: .destructive) {
                        historyService.deleteAll()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .buttonStyle(.borderless)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索原文或译文...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        searchDebouncer.send(newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        debouncedSearchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            HStack(spacing: 16) {
                Picker("", selection: $selectedTab) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                
                Spacer()
                
                filterMenus
            }
        }
        .padding()
    }
    
    private var filterMenus: some View {
        HStack(spacing: 8) {
            Menu {
                Button("全部来源") { selectedSourceFilter = nil }
                Divider()
                Button("选中文本") { selectedSourceFilter = .selection }
                Button("OCR 识别") { selectedSourceFilter = .ocr }
                Button("手动输入") { selectedSourceFilter = .manual }
            } label: {
                HStack(spacing: 4) {
                    Text(sourceFilterLabel)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedSourceFilter != nil ? Color.accentColor.opacity(0.1) : Color.clear)
                .cornerRadius(6)
            }
            .buttonStyle(.borderless)
            
            Menu {
                Button("全部引擎") { selectedProviderFilter = nil }
                Divider()
                Button("Google") { selectedProviderFilter = "Google Translate (Web)" }
                Button("OpenAI") { selectedProviderFilter = "OpenAI" }
                Button("Claude") { selectedProviderFilter = "Claude" }
                Button("DeepSeek") { selectedProviderFilter = "DeepSeek" }
            } label: {
                HStack(spacing: 4) {
                    Text(providerFilterLabel)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedProviderFilter != nil ? Color.accentColor.opacity(0.1) : Color.clear)
                .cornerRadius(6)
            }
            .buttonStyle(.borderless)
        }
    }
    
    private var sourceFilterLabel: String {
        guard let filter = selectedSourceFilter else { return "来源" }
        switch filter {
        case .selection: return "选中"
        case .ocr: return "OCR"
        case .manual: return "手动"
        }
    }
    
    private var providerFilterLabel: String {
        selectedProviderFilter?.components(separatedBy: " ").first ?? "引擎"
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "暂无翻译历史" : "未找到匹配结果")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Button("清除搜索") {
                    searchText = ""
                    debouncedSearchText = ""
                }
                .buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var historyListView: some View {
        List(selection: $selectedHistory) {
            ForEach(filteredHistory, id: \.id) { history in
                HistoryRowView(history: history)
                    .tag(history)
                    .contextMenu {
                        Button("复制原文") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(history.originalText, forType: .string)
                        }
                        Button("复制译文") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(history.translatedText, forType: .string)
                        }
                        Divider()
                        Button(history.isFavorite ? "取消收藏" : "收藏") {
                            historyService.toggleFavorite(history)
                        }
                        Divider()
                        Button("删除", role: .destructive) {
                            historyService.delete(history)
                        }
                    }
            }
        }
        .listStyle(.inset)
    }
}

struct HistoryRowView: View {
    let history: TranslationHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sourceTypeIcon
                
                Text(history.provider)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if history.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                
                Text(history.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(history.originalText)
                .font(.body)
                .lineLimit(2)
            
            Text(history.translatedText)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    private var sourceTypeIcon: some View {
        Group {
            switch history.sourceType {
            case .selection:
                Image(systemName: "text.cursor")
            case .ocr:
                Image(systemName: "doc.text.viewfinder")
            case .manual:
                Image(systemName: "keyboard")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
}

struct ExportSheet: View {
    let historyService: HistoryService
    @Environment(\.dismiss) private var dismiss
    @State private var exportMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("导出历史记录")
                .font(.headline)
            
            Text("将翻译历史导出为 JSON 文件")
                .foregroundColor(.secondary)
            
            if !exportMessage.isEmpty {
                Text(exportMessage)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("导出") {
                    exportHistory()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 300)
    }
    
    private func exportHistory() {
        guard let data = historyService.exportToJSON() else {
            exportMessage = "导出失败"
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "LinguaFloat_History_\(Date().ISO8601Format()).json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try data.write(to: url)
                exportMessage = "导出成功"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            } catch {
                exportMessage = "导出失败: \(error.localizedDescription)"
            }
        }
    }
}
