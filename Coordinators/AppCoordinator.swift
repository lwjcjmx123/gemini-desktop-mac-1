//
//  AppCoordinator.swift
//  SwiftBrowser
//

import SwiftUI
import AppKit
import WebKit
import KeyboardShortcuts

extension Notification.Name {
    static let openMainWindow = Notification.Name("openMainWindow")
    static let saveTabsBeforeTermination = Notification.Name("saveTabsBeforeTermination")
}

@Observable
class AppCoordinator {
    var tabManager = TabManager()
    let hotCornerMonitor = HotCornerMonitor()
    @ObservationIgnored private var isHotCornerAnimating = false
    @ObservationIgnored private var windowMoveObserver: Any?
    @ObservationIgnored private var clickOutsideMonitor: Any?
    @ObservationIgnored private var isHotCornerVisible = false
    @ObservationIgnored private var savedWindowLevel: NSWindow.Level = .normal
    @ObservationIgnored private var savedCollectionBehavior: NSWindow.CollectionBehavior = []

    var openWindowAction: ((String) -> Void)?

    var canGoBack: Bool { tabManager.selectedTab?.webViewModel.canGoBack ?? false }
    var canGoForward: Bool { tabManager.selectedTab?.webViewModel.canGoForward ?? false }

    init() {
        // Observe notifications for window opening
        NotificationCenter.default.addObserver(forName: .openMainWindow, object: nil, queue: .main) { [weak self] _ in
            self?.openMainWindow()
        }

        // Save tabs before app terminates
        NotificationCenter.default.addObserver(forName: .saveTabsBeforeTermination, object: nil, queue: .main) { [weak self] _ in
            self?.tabManager.saveTabs()
        }

        // Setup hot corner
        setupHotCorner()

        // Setup keyboard shortcut
        setupKeyboardShortcut()

        // Apply proxy settings immediately on launch
        ProxyHelper.applyCurrentSettings()
    }

    // MARK: - Navigation (delegates to selected tab)

    func goBack() { tabManager.selectedTab?.webViewModel.goBack() }
    func goForward() { tabManager.selectedTab?.webViewModel.goForward() }
    func goHome() { tabManager.selectedTab?.webViewModel.loadHome() }
    func reload() { tabManager.selectedTab?.webViewModel.reload() }

    // MARK: - Zoom

    func zoomIn() { tabManager.selectedTab?.webViewModel.zoomIn() }
    func zoomOut() { tabManager.selectedTab?.webViewModel.zoomOut() }
    func resetZoom() { tabManager.selectedTab?.webViewModel.resetZoom() }

    // MARK: - Tab Management

    func newTab() {
        tabManager.createTab()
    }

    func closeCurrentTab() {
        guard let id = tabManager.selectedTabID else { return }
        tabManager.closeTab(id)
    }

    // MARK: - History

    func showHistory() {
        // Open Settings window and switch to History tab
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    // MARK: - Window Management

    func openMainWindow(on targetScreen: NSScreen? = nil) {
        let hideDockIcon = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hideDockIcon.rawValue)
        if !hideDockIcon {
            NSApp.setActivationPolicy(.regular)
        }

        let mainWindow = findMainWindow()

        if let window = mainWindow {
            if let screen = targetScreen {
                centerWindow(window, on: screen)
            }
            window.makeKeyAndOrderFront(nil)
        } else if let openWindowAction = openWindowAction {
            openWindowAction("main")
            if let screen = targetScreen {
                centerNewlyCreatedWindow(on: screen)
            }
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func showApp() {
        showAppFromHotCorner()
    }

    func hideApp() {
        hideAppToHotCorner()
    }

    /// Show main window sliding in from bottom-left corner
    private func showAppFromHotCorner() {
        guard !isHotCornerAnimating else { return }

        let screen = NSScreen.screenAtMouseLocation() ?? NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.frame

        let existingWindow = findMainWindow()

        if let window = existingWindow {
            isHotCornerAnimating = true
            let windowSize = window.frame.size

            // Save original window properties
            savedWindowLevel = window.level
            savedCollectionBehavior = window.collectionBehavior

            // Make window float above fullscreen apps
            window.level = .mainMenu
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

            // Target position: saved position or default bottom-left (use full frame to ignore Stage Manager)
            let endOrigin = savedWindowOrigin() ?? NSPoint(
                x: screenFrame.origin.x + 20,
                y: screenFrame.origin.y + 20
            )
            let endFrame = NSRect(origin: endOrigin, size: windowSize)

            // Start position: off-screen towards bottom-left
            let startOrigin = NSPoint(
                x: endOrigin.x - windowSize.width - 100,
                y: endOrigin.y - windowSize.height - 100
            )
            let startFrame = NSRect(origin: startOrigin, size: windowSize)

            // Place off-screen first (hidden)
            window.alphaValue = 0
            window.setFrame(startFrame, display: false)
            window.orderFrontRegardless()
            window.setFrame(startFrame, display: false)
            window.makeKey()
            NSApp.activate(ignoringOtherApps: true)

            // Show and slide to target position in next run loop
            DispatchQueue.main.async { [weak self] in
                window.alphaValue = 1
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.12
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    context.allowsImplicitAnimation = true
                    window.setFrame(endFrame, display: true, animate: true)
                }, completionHandler: {
                    self?.isHotCornerAnimating = false
                    self?.isHotCornerVisible = true
                    self?.startObservingWindowMove(window)
                    self?.startClickOutsideMonitor()
                })
            }
        } else if let openWindowAction = openWindowAction {
            isHotCornerAnimating = true
            openWindowAction("main")
            NSApp.activate(ignoringOtherApps: true)
            positionNewWindowFromHotCorner(on: screen)
        }
    }

    /// Hide main window sliding out to bottom-left corner, then orderOut
    private func hideAppToHotCorner() {
        guard !isHotCornerAnimating else { return }

        let mainWindow = findMainWindow()
        guard let window = mainWindow, window.isVisible else { return }

        saveWindowOrigin(window.frame.origin)
        stopObservingWindowMove()
        stopClickOutsideMonitor()

        isHotCornerAnimating = true

        // Prevent Stage Manager from capturing during animation
        window.collectionBehavior = [.stationary, .canJoinAllSpaces, .fullScreenAuxiliary]

        let currentFrame = window.frame
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]

        // Slide just past the bottom-left edge of the screen
        let offScreenOrigin = NSPoint(
            x: screen.frame.origin.x - currentFrame.width,
            y: screen.frame.origin.y - currentFrame.height
        )
        let offScreenFrame = NSRect(origin: offScreenOrigin, size: currentFrame.size)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            context.allowsImplicitAnimation = true
            window.setFrame(offScreenFrame, display: true, animate: true)
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            if let self = self {
                window.level = self.savedWindowLevel
                window.collectionBehavior = self.savedCollectionBehavior
            }
            self?.isHotCornerAnimating = false
            self?.isHotCornerVisible = false
        })
    }

    private func positionNewWindowFromHotCorner(on screen: NSScreen, attempt: Int = 1) {
        let maxAttempts = 5
        let retryDelay = 0.05

        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            guard let self = self else { return }

            if let window = self.findMainWindow() {
                let screenFrame = screen.frame
                let windowSize = window.frame.size

                self.savedWindowLevel = window.level
                self.savedCollectionBehavior = window.collectionBehavior
                window.level = .mainMenu
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

                let endOrigin = self.savedWindowOrigin() ?? NSPoint(
                    x: screenFrame.origin.x + 20,
                    y: screenFrame.origin.y + 20
                )
                let endFrame = NSRect(origin: endOrigin, size: windowSize)

                let startOrigin = NSPoint(
                    x: endOrigin.x - windowSize.width - 100,
                    y: endOrigin.y - windowSize.height - 100
                )
                let startFrame = NSRect(origin: startOrigin, size: windowSize)

                window.setFrame(startFrame, display: false)
                window.makeKeyAndOrderFront(nil)

                DispatchQueue.main.async {
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.12
                        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                        context.allowsImplicitAnimation = true
                        window.setFrame(endFrame, display: true, animate: true)
                    }, completionHandler: { [weak self] in
                        self?.isHotCornerAnimating = false
                        self?.isHotCornerVisible = true
                        if let window = self?.findMainWindow() {
                            self?.startObservingWindowMove(window)
                        }
                        self?.startClickOutsideMonitor()
                    })
                }
            } else if attempt < maxAttempts {
                self.positionNewWindowFromHotCorner(on: screen, attempt: attempt + 1)
            }
        }
    }

    // MARK: - Window Position Persistence

    private func saveWindowOrigin(_ origin: NSPoint) {
        let defaults = UserDefaults.standard
        defaults.set(Double(origin.x), forKey: UserDefaultsKeys.hotCornerWindowX.rawValue)
        defaults.set(Double(origin.y), forKey: UserDefaultsKeys.hotCornerWindowY.rawValue)
        defaults.set(true, forKey: UserDefaultsKeys.hotCornerWindowSaved.rawValue)
    }

    private func savedWindowOrigin() -> NSPoint? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: UserDefaultsKeys.hotCornerWindowSaved.rawValue) else { return nil }
        let x = defaults.double(forKey: UserDefaultsKeys.hotCornerWindowX.rawValue)
        let y = defaults.double(forKey: UserDefaultsKeys.hotCornerWindowY.rawValue)
        return NSPoint(x: x, y: y)
    }

    private func startObservingWindowMove(_ window: NSWindow) {
        stopObservingWindowMove()
        windowMoveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            self?.saveWindowOrigin(window.frame.origin)
        }
    }

    private func stopObservingWindowMove() {
        if let observer = windowMoveObserver {
            NotificationCenter.default.removeObserver(observer)
            windowMoveObserver = nil
        }
    }

    private func startClickOutsideMonitor() {
        stopClickOutsideMonitor()
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, !self.isHotCornerAnimating else { return }
            // Check if click is outside our window
            if let window = self.findMainWindow(), window.isVisible {
                let screenLocation = NSEvent.mouseLocation
                if !window.frame.contains(screenLocation) {
                    self.hideApp()
                }
            }
        }
    }

    private func stopClickOutsideMonitor() {
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
    }

    // MARK: - Hot Corner

    private func setupHotCorner() {
        let enabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.hotCornerEnabled.rawValue)
        hotCornerMonitor.isEnabled = enabled

        hotCornerMonitor.onTrigger = { [weak self] in
            guard let self = self else { return }
            // Check actual window visibility instead of relying on state
            if let window = self.findMainWindow(), window.isVisible {
                self.hideApp()
            } else {
                self.showApp()
            }
        }
    }

    func updateHotCornerEnabled(_ enabled: Bool) {
        hotCornerMonitor.isEnabled = enabled
    }

    // MARK: - Keyboard Shortcut

    private func setupKeyboardShortcut() {
        KeyboardShortcuts.onKeyDown(for: .toggleWindow) { [weak self] in
            guard let self = self else { return }
            if let window = self.findMainWindow(), window.isVisible {
                self.hideApp()
            } else {
                self.showApp()
            }
        }
    }

    // MARK: - Private

    private func findMainWindow() -> NSWindow? {
        NSApp.windows.first {
            $0.identifier?.rawValue == Constants.mainWindowIdentifier || $0.title == Constants.mainWindowTitle
        }
    }

    private func centerWindow(_ window: NSWindow, on screen: NSScreen) {
        let origin = screen.centerPoint(for: window.frame.size)
        window.setFrameOrigin(origin)
    }

    private func centerNewlyCreatedWindow(on screen: NSScreen, attempt: Int = 1) {
        let maxAttempts = 5
        let retryDelay = 0.05

        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            guard let self = self else { return }

            if let window = self.findMainWindow() {
                self.centerWindow(window, on: screen)
            } else if attempt < maxAttempts {
                self.centerNewlyCreatedWindow(on: screen, attempt: attempt + 1)
            }
        }
    }
}


extension AppCoordinator {

    struct Constants {
        static let mainWindowIdentifier = "main"
        static let mainWindowTitle = "Swift Browser"
    }

}
