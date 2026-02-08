//
//  AppDelegate.swift
//  SwiftBrowser
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Always open main window when dock icon is clicked
        NotificationCenter.default.post(name: .openMainWindow, object: nil)
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.post(name: .saveTabsBeforeTermination, object: nil)
    }
}
