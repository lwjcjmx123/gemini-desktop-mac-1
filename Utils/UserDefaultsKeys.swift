//
//  UserDefaultsKeys.swift
//  SwiftBrowser
//

import Foundation

enum UserDefaultsKeys: String {
    case pageZoom
    case hideWindowAtLaunch
    case hideDockIcon
    // Proxy
    case proxyEnabled
    case proxyHost
    case proxyPort
    // Hot Corner
    case hotCornerEnabled
    case hotCornerWindowX
    case hotCornerWindowY
    case hotCornerWindowSaved
    // Tab Persistence
    case savedTabs
    case savedSelectedTabIndex
}
