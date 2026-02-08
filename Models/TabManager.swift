//
//  TabManager.swift
//  SwiftBrowser
//

import Foundation

@Observable
class TabManager {
    var tabs: [BrowserTab] = []
    var selectedTabID: UUID?

    var selectedTab: BrowserTab? {
        guard let id = selectedTabID else { return nil }
        return tabs.first { $0.id == id }
    }

    init() {
        restoreTabs()
    }

    @discardableResult
    func createTab(url: URL? = nil) -> BrowserTab {
        let tab = BrowserTab(url: url)
        tabs.append(tab)
        selectedTabID = tab.id
        return tab
    }

    func closeTab(_ id: UUID) {
        guard tabs.count > 0 else { return }

        if let index = tabs.firstIndex(where: { $0.id == id }) {
            let wasSelected = selectedTabID == id
            tabs.remove(at: index)

            if wasSelected {
                if tabs.isEmpty {
                    selectedTabID = nil
                } else {
                    // Select the tab at the same index, or the last one
                    let newIndex = min(index, tabs.count - 1)
                    selectedTabID = tabs[newIndex].id
                }
            }
        }
    }

    func selectTab(_ id: UUID) {
        selectedTabID = id
    }

    // MARK: - Tab Persistence

    func saveTabs() {
        var savedTabs: [[String: String]] = []
        for tab in tabs {
            let urlString = tab.url
            guard !urlString.isEmpty, URL(string: urlString) != nil else { continue }
            savedTabs.append([
                "url": urlString,
                "title": tab.title
            ])
        }

        let defaults = UserDefaults.standard
        defaults.set(savedTabs, forKey: UserDefaultsKeys.savedTabs.rawValue)

        if let selectedID = selectedTabID,
           let index = tabs.firstIndex(where: { $0.id == selectedID }) {
            defaults.set(index, forKey: UserDefaultsKeys.savedSelectedTabIndex.rawValue)
        }
    }

    private func restoreTabs() {
        let defaults = UserDefaults.standard
        guard let savedTabs = defaults.array(forKey: UserDefaultsKeys.savedTabs.rawValue) as? [[String: String]],
              !savedTabs.isEmpty else {
            // No saved data — create a blank tab
            let tab = BrowserTab()
            tabs.append(tab)
            selectedTabID = tab.id
            return
        }

        for entry in savedTabs {
            guard let urlString = entry["url"], let url = URL(string: urlString) else { continue }
            let title = entry["title"]
            let tab = BrowserTab(url: url, restoredTitle: title)
            tabs.append(tab)
        }

        if tabs.isEmpty {
            // All entries were invalid — fall back to blank tab
            let tab = BrowserTab()
            tabs.append(tab)
            selectedTabID = tab.id
            return
        }

        let savedIndex = defaults.integer(forKey: UserDefaultsKeys.savedSelectedTabIndex.rawValue)
        let clampedIndex = min(savedIndex, tabs.count - 1)
        selectedTabID = tabs[clampedIndex].id
    }
}
