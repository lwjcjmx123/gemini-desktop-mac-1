import SwiftUI
import WebKit
import ServiceManagement
import KeyboardShortcuts

struct SettingsView: View {
    @Binding var coordinator: AppCoordinator

    var body: some View {
        TabView {
            GeneralSettingsTab(coordinator: $coordinator)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            PrivacySettingsTab()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }

            SiteDataView()
                .tabItem {
                    Label("Site Data", systemImage: "externaldrive")
                }

            HistoryView(onNavigate: { url in
                coordinator.tabManager.selectedTab?.webViewModel.loadURL(url)
                // Close settings window
                NSApp.windows.first { $0.title == "Settings" || $0.identifier?.rawValue.contains("settings") == true }?.close()
            })
            .tabItem {
                Label("History", systemImage: "clock")
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsTab: View {
    @Binding var coordinator: AppCoordinator
    @AppStorage(UserDefaultsKeys.pageZoom.rawValue) private var pageZoom: Double = Constants.defaultPageZoom
    @AppStorage(UserDefaultsKeys.hideWindowAtLaunch.rawValue) private var hideWindowAtLaunch: Bool = false
    @AppStorage(UserDefaultsKeys.hideDockIcon.rawValue) private var hideDockIcon: Bool = false
    @AppStorage(UserDefaultsKeys.hotCornerEnabled.rawValue) private var hotCornerEnabled: Bool = false

    // Proxy settings
    @AppStorage(UserDefaultsKeys.proxyEnabled.rawValue) private var proxyEnabled: Bool = false
    @AppStorage(UserDefaultsKeys.proxyHost.rawValue) private var proxyHost: String = "127.0.0.1"
    @AppStorage(UserDefaultsKeys.proxyPort.rawValue) private var proxyPort: Int = 7890
    @State private var showProxyRestartHint = false

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch MenuBar at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            try newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                        } catch { launchAtLogin = !newValue }
                    }
                Toggle("Hide Desktop Window at Launch", isOn: $hideWindowAtLaunch)
                Toggle("Hide Dock Icon", isOn: $hideDockIcon)
                    .onChange(of: hideDockIcon) { _, newValue in
                        NSApp.setActivationPolicy(newValue ? .accessory : .regular)
                    }
                Toggle("Hot Corner Trigger (Bottom-Left)", isOn: $hotCornerEnabled)
                    .onChange(of: hotCornerEnabled) { _, newValue in
                        coordinator.updateHotCornerEnabled(newValue)
                    }
                HStack {
                    Text("Toggle Window Shortcut")
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .toggleWindow)
                }
            }

            Section("Appearance") {
                HStack {
                    Text("Text Size: \(Int((pageZoom * 100).rounded()))%")
                    Spacer()
                    Stepper("",
                            value: $pageZoom,
                            in: Constants.minPageZoom...Constants.maxPageZoom,
                            step: Constants.pageZoomStep)
                        .onChange(of: pageZoom) { _, newValue in
                            coordinator.tabManager.selectedTab?.webViewModel.wkWebView.pageZoom = newValue
                        }
                        .labelsHidden()
                }
            }

            Section("Network") {
                Toggle("Enable SOCKS5 Proxy", isOn: $proxyEnabled)
                    .onChange(of: proxyEnabled) { _, _ in showProxyRestartHint = true }

                if proxyEnabled {
                    HStack {
                        Text("Host:")
                        TextField("127.0.0.1", text: $proxyHost)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: proxyHost) { _, _ in showProxyRestartHint = true }
                    }
                    HStack {
                        Text("Port:")
                        TextField("1080", value: $proxyPort, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onChange(of: proxyPort) { _, _ in showProxyRestartHint = true }
                    }
                }

                if showProxyRestartHint {
                    Text("Proxy settings saved. Restart the app to apply changes.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
    }

    struct Constants {
        static let defaultPageZoom: Double = 1.0
        static let minPageZoom: Double = 0.6
        static let maxPageZoom: Double = 1.4
        static let pageZoomStep: Double = 0.01
    }
}

// MARK: - Privacy Settings Tab

struct PrivacySettingsTab: View {
    @State private var showingResetAlert = false
    @State private var isClearing = false

    var body: some View {
        Form {
            Section("Website Data") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Reset All Website Data")
                        Text("Clears cookies, cache, and login sessions for all sites")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reset All", role: .destructive) { showingResetAlert = true }
                        .disabled(isClearing)
                        .overlay { if isClearing { ProgressView().scaleEffect(0.7) } }
                }
            }

            Section("Browsing History") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Clear Browsing History")
                        Text("Removes all recorded page visits")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Clear History", role: .destructive) {
                        HistoryManager.shared.clearAll()
                    }
                    .disabled(HistoryManager.shared.items.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        .alert("Reset All Website Data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { clearWebsiteData() }
        } message: {
            Text("This will clear all cookies, cache, and login sessions. You will need to sign in again.")
        }
    }

    private func clearWebsiteData() {
        isClearing = true
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: types) { records in
            dataStore.removeData(ofTypes: types, for: records) {
                DispatchQueue.main.async { isClearing = false }
            }
        }
    }
}

extension SettingsView {

    struct Constants {
        static let defaultPageZoom: Double = 1.0
        static let minPageZoom: Double = 0.6
        static let maxPageZoom: Double = 1.4
        static let pageZoomStep: Double = 0.01
    }

}
