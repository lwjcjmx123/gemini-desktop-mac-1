//
//  ProxyHelper.swift
//  SwiftBrowser
//

import WebKit
import Network

enum ProxyHelper {

    /// Applies proxy to the WKWebsiteDataStore using the official Network framework API (macOS 14.0+).
    /// Configures both HTTP CONNECT and SOCKS5 proxy for maximum compatibility.
    static func applyProxy(to dataStore: WKWebsiteDataStore, host: String, port: Int) {
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: UInt16(port))!
        let endpoint = NWEndpoint.hostPort(host: nwHost, port: nwPort)

        var configs: [ProxyConfiguration] = []

        // HTTP CONNECT proxy — handles HTTP/HTTPS traffic
        let httpProxy = ProxyConfiguration(httpCONNECTProxy: endpoint)
        configs.append(httpProxy)
        print("[Proxy] Added HTTP CONNECT proxy: \(host):\(port)")

        // SOCKS5 proxy — handles all TCP traffic
        let socksProxy = ProxyConfiguration(socksv5Proxy: endpoint)
        configs.append(socksProxy)
        print("[Proxy] Added SOCKS5 proxy: \(host):\(port)")

        dataStore.proxyConfigurations = configs
        print("[Proxy] Applied \(configs.count) proxy configurations to WKWebsiteDataStore")
    }
}
