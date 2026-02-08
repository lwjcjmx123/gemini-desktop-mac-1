//
//  MainWindowView.swift
//  SwiftBrowser
//

import SwiftUI
import AppKit

struct MainWindowView: View {
    @Binding var coordinator: AppCoordinator
    @Environment(\.openWindow) private var openWindow
    @State private var addressText: String = ""
    @State private var shouldFocusAddressBar: Bool = false

    private var selectedTab: BrowserTab? {
        coordinator.tabManager.selectedTab
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(tabManager: coordinator.tabManager)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            if let tab = selectedTab {
                BrowserWebView(webView: tab.webViewModel.wkWebView)
                    .id(tab.id)
                    .onChange(of: tab.url) { _, newURL in
                        addressText = newURL
                    }
                    .onAppear {
                        addressText = tab.url
                    }
            } else {
                emptyState
            }
        }
        .onChange(of: coordinator.tabManager.selectedTabID) { _, _ in
            if let tab = selectedTab {
                addressText = tab.url
                if tab.url.isEmpty {
                    shouldFocusAddressBar = true
                }
            }
        }
        .onAppear {
            coordinator.openWindowAction = { id in
                openWindow(id: id)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    coordinator.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .help("Back")
                .disabled(!coordinator.canGoBack)
            }

            ToolbarItem(placement: .navigation) {
                Button {
                    coordinator.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .help("Forward")
                .disabled(!coordinator.canGoForward)
            }

            ToolbarItem(placement: .principal) {
                AddressBarView(
                    urlText: $addressText,
                    shouldFocus: $shouldFocusAddressBar,
                    isSecure: addressText.hasPrefix("https://"),
                    isLoading: selectedTab?.isLoading ?? false,
                    onCommit: { text in
                        selectedTab?.webViewModel.loadURL(text)
                    },
                    onReload: {
                        coordinator.reload()
                    }
                )
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    coordinator.newTab()
                } label: {
                    Image(systemName: "plus")
                }
                .help("New Tab")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(.quaternary)
            Text("No Tab Open")
                .font(.title3)
                .foregroundStyle(.tertiary)
            Button {
                coordinator.newTab()
            } label: {
                Label("New Tab", systemImage: "plus")
                    .font(.system(size: 13))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
