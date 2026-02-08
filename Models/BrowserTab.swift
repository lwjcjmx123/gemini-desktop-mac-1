//
//  BrowserTab.swift
//  SwiftBrowser
//

import Foundation

@Observable
class BrowserTab: Identifiable {
    let id: UUID
    let webViewModel: WebViewModel
    private var restoredTitle: String?

    var title: String {
        let liveTitle = webViewModel.pageTitle
        if !liveTitle.isEmpty {
            restoredTitle = nil
            return liveTitle
        }
        return restoredTitle ?? liveTitle
    }
    var url: String { webViewModel.currentURL }
    var isLoading: Bool { webViewModel.isLoading }

    init(url: URL? = nil, restoredTitle: String? = nil) {
        self.id = UUID()
        self.restoredTitle = restoredTitle
        self.webViewModel = WebViewModel(initialURL: url)
    }
}
