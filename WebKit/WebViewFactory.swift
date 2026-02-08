//
//  WebViewFactory.swift
//  SwiftBrowser
//

import WebKit

enum WebViewFactory {

    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    /// Creates a WKWebViewConfiguration with user scripts and optional proxy.
    static func makeConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()

        // Configure data store with proxy if enabled
        let dataStore = WKWebsiteDataStore.default()
        let proxyEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.proxyEnabled.rawValue)
        if proxyEnabled {
            let host = UserDefaults.standard.string(forKey: UserDefaultsKeys.proxyHost.rawValue) ?? "127.0.0.1"
            let port = UserDefaults.standard.integer(forKey: UserDefaultsKeys.proxyPort.rawValue)
            let effectivePort = port > 0 ? port : 7890
            ProxyHelper.applyProxy(to: dataStore, host: host, port: effectivePort)
        }
        configuration.websiteDataStore = dataStore

        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Add user scripts
        for script in UserScripts.createAllScripts() {
            configuration.userContentController.addUserScript(script)
        }

        // Register console log message handler (debug only)
        #if DEBUG
        let handler = ConsoleLogHandler()
        configuration.userContentController.add(handler, name: UserScripts.consoleLogHandler)
        #endif

        return configuration
    }

    /// Creates a configured WKWebView ready for use.
    static func makeWebView(configuration: WKWebViewConfiguration? = nil) -> WKWebView {
        let config = configuration ?? makeConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.customUserAgent = userAgent

        let savedZoom = UserDefaults.standard.double(forKey: UserDefaultsKeys.pageZoom.rawValue)
        webView.pageZoom = savedZoom > 0 ? savedZoom : 1.0

        return webView
    }
}
