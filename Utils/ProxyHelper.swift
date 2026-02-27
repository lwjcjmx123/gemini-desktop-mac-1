//
//  ProxyHelper.swift
//  SwiftBrowser
//

import WebKit
import Network

enum ProxyHelper {

    /// Applies proxy to the WKWebsiteDataStore using the official Network framework API (macOS 14.0+).
    /// Configures both HTTP CONNECT and SOCKS5 proxy for maximum compatibility.
    /// 根据传入参数设置代理到指定 DataStore
    static func applyProxy(to dataStore: WKWebsiteDataStore, host: String, port: Int) {
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: UInt16(port))!
        let endpoint = NWEndpoint.hostPort(host: nwHost, port: nwPort)

        // SOCKS5 proxy — handles all TCP traffic (including HTTP/HTTPS)
        let socksProxy = ProxyConfiguration(socksv5Proxy: endpoint)
        dataStore.proxyConfigurations = [socksProxy]
        print("[Proxy] Applied SOCKS5 proxy: \(host):\(port)")
    }

    /// 读取当前 UserDefaults 设置，立刻更新全局 WKWebsiteDataStore，无需重启 App
    static func applyCurrentSettings() {
        let dataStore = WKWebsiteDataStore.default()
        let enabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.proxyEnabled.rawValue)
        if enabled {
            let host = UserDefaults.standard.string(forKey: UserDefaultsKeys.proxyHost.rawValue) ?? "127.0.0.1"
            let port = UserDefaults.standard.integer(forKey: UserDefaultsKeys.proxyPort.rawValue)
            let effectivePort = port > 0 ? port : 7890
            applyProxy(to: dataStore, host: host, port: effectivePort)
        } else {
            dataStore.proxyConfigurations = []
            print("[Proxy] Proxy disabled, cleared proxy configurations")
        }
    }
}
