//
//  WebViewModel.swift
//  SwiftBrowser
//

import WebKit
import Combine

/// Handles console.log messages from JavaScript
class ConsoleLogHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let body = message.body as? String {
            print("[WebView] \(body)")
        }
    }
}

/// Observable wrapper around WKWebView supporting arbitrary URLs
@Observable
class WebViewModel {

    // MARK: - Constants

    static let defaultHomeURL = URL(string: "https://gemini.google.com/app")!
    static let defaultPageZoom: Double = 1.0
    private static let minZoom: Double = 0.6
    private static let maxZoom: Double = 1.4

    // MARK: - Public Properties

    let wkWebView: WKWebView
    private(set) var canGoBack: Bool = false
    private(set) var canGoForward: Bool = false
    private(set) var currentURL: String = ""
    private(set) var pageTitle: String = "New Tab"
    private(set) var isLoading: Bool = false

    // MARK: - Private Properties

    private var backObserver: NSKeyValueObservation?
    private var forwardObserver: NSKeyValueObservation?
    private var urlObserver: NSKeyValueObservation?
    private var titleObserver: NSKeyValueObservation?
    private var loadingObserver: NSKeyValueObservation?

    // MARK: - Initialization

    init(initialURL: URL? = nil, configuration: WKWebViewConfiguration? = nil) {
        self.wkWebView = WebViewFactory.makeWebView(configuration: configuration)
        setupObservers()
        if let url = initialURL {
            wkWebView.load(URLRequest(url: url))
        }
    }

    // MARK: - Navigation

    func loadHome() {
        wkWebView.load(URLRequest(url: Self.defaultHomeURL))
    }

    /// Smart URL loading: detects URLs, domains, and search queries
    func loadURL(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let url = asURL(trimmed) {
            wkWebView.load(URLRequest(url: url))
        } else {
            // Treat as search query
            let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            if let searchURL = URL(string: "https://www.google.com/search?q=\(query)&hl=en&gl=US") {
                wkWebView.load(URLRequest(url: searchURL))
            }
        }
    }

    func goBack() { wkWebView.goBack() }
    func goForward() { wkWebView.goForward() }
    func reload() { wkWebView.reload() }

    // MARK: - Zoom

    func zoomIn() {
        let newZoom = min((wkWebView.pageZoom * 100 + 1).rounded() / 100, Self.maxZoom)
        setZoom(newZoom)
    }

    func zoomOut() {
        let newZoom = max((wkWebView.pageZoom * 100 - 1).rounded() / 100, Self.minZoom)
        setZoom(newZoom)
    }

    func resetZoom() {
        setZoom(Self.defaultPageZoom)
    }

    private func setZoom(_ zoom: Double) {
        wkWebView.pageZoom = zoom
        UserDefaults.standard.set(zoom, forKey: UserDefaultsKeys.pageZoom.rawValue)
    }

    // MARK: - Private

    private func asURL(_ input: String) -> URL? {
        // Already has scheme
        if input.hasPrefix("http://") || input.hasPrefix("https://") {
            return URL(string: input)
        }
        // Looks like a domain (contains dot, no spaces)
        if input.contains(".") && !input.contains(" ") {
            return URL(string: "https://\(input)")
        }
        return nil
    }

    private func setupObservers() {
        backObserver = wkWebView.observe(\.canGoBack, options: [.new, .initial]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.canGoBack = webView.canGoBack
            }
        }

        forwardObserver = wkWebView.observe(\.canGoForward, options: [.new, .initial]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.canGoForward = webView.canGoForward
            }
        }

        urlObserver = wkWebView.observe(\.url, options: [.new, .initial]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.currentURL = webView.url?.absoluteString ?? ""
            }
        }

        titleObserver = wkWebView.observe(\.title, options: [.new, .initial]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                let title = webView.title ?? ""
                self?.pageTitle = title.isEmpty ? "New Tab" : title
            }
        }

        loadingObserver = wkWebView.observe(\.isLoading, options: [.new, .initial]) { [weak self] webView, _ in
            DispatchQueue.main.async {
                self?.isLoading = webView.isLoading
            }
        }
    }
}
