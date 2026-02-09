//
//  HistoryManager.swift
//  SwiftBrowser
//

import Foundation

struct HistoryItem: Identifiable, Codable {
    let id: UUID
    let url: String
    let title: String
    let timestamp: Date

    init(url: String, title: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.timestamp = timestamp
    }

    var domain: String {
        URL(string: url)?.host ?? ""
    }
}

@Observable
class HistoryManager {
    private(set) var items: [HistoryItem] = []
    private let storageKey = "browsingHistory"
    private let maxItems = 5000

    static let shared = HistoryManager()

    private init() {
        load()
    }

    func addItem(url: String, title: String) {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty, URL(string: trimmedURL) != nil else { return }

        // Skip blank/empty pages
        if trimmedURL == "about:blank" { return }

        // Avoid duplicate consecutive entries
        if let last = items.first, last.url == trimmedURL {
            return
        }

        let item = HistoryItem(url: trimmedURL, title: title.isEmpty ? trimmedURL : title)
        items.insert(item, at: 0)

        // Trim to max size
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        save()
    }

    func removeItems(_ ids: Set<UUID>) {
        items.removeAll { ids.contains($0.id) }
        save()
    }

    func clearAll() {
        items.removeAll()
        save()
    }

    func clearItems(forDomain domain: String) {
        items.removeAll { $0.domain == domain }
        save()
    }

    func search(_ query: String) -> [HistoryItem] {
        let q = query.lowercased()
        return items.filter {
            $0.url.lowercased().contains(q) || $0.title.lowercased().contains(q)
        }
    }

    // MARK: - Grouped by date

    func groupedByDate(_ filteredItems: [HistoryItem]? = nil) -> [(String, [HistoryItem])] {
        let source = filteredItems ?? items
        let calendar = Calendar.current
        let formatter = DateFormatter()

        var groups: [(String, [HistoryItem])] = []
        var currentKey = ""
        var currentItems: [HistoryItem] = []

        for item in source {
            let key: String
            if calendar.isDateInToday(item.timestamp) {
                key = "Today"
            } else if calendar.isDateInYesterday(item.timestamp) {
                key = "Yesterday"
            } else if let daysAgo = calendar.dateComponents([.day], from: item.timestamp, to: Date()).day, daysAgo < 7 {
                formatter.dateFormat = "EEEE"
                key = formatter.string(from: item.timestamp)
            } else {
                formatter.dateFormat = "yyyy-MM-dd"
                key = formatter.string(from: item.timestamp)
            }

            if key != currentKey {
                if !currentItems.isEmpty {
                    groups.append((currentKey, currentItems))
                }
                currentKey = key
                currentItems = [item]
            } else {
                currentItems.append(item)
            }
        }
        if !currentItems.isEmpty {
            groups.append((currentKey, currentItems))
        }

        return groups
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return
        }
        items = decoded
    }
}
