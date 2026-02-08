//
//  HotCornerMonitor.swift
//  SwiftBrowser
//

import AppKit
import CoreGraphics

class HotCornerMonitor {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var nsEventMonitor: Any?
    private var lastTriggerTime: Date = .distantPast
    private let cooldown: TimeInterval = 0.8
    private let cornerSize: CGFloat = 20.0

    // Cached screen info for use in CGEvent callback (avoid accessing NSScreen off main thread)
    private var cachedScreenCorners: [(corner: NSRect, screen: NSRect)] = []
    private var cachedPrimaryHeight: CGFloat = 0

    var onTrigger: (() -> Void)?

    var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    deinit {
        stopMonitoring()
    }

    private func updateScreenCache() {
        cachedPrimaryHeight = NSScreen.screens.first?.frame.height ?? 0
        cachedScreenCorners = NSScreen.screens.map { screen in
            let f = screen.frame
            let corner = NSRect(x: f.origin.x, y: f.origin.y, width: cornerSize, height: cornerSize)
            return (corner: corner, screen: f)
        }
    }

    private func startMonitoring() {
        stopMonitoring()
        updateScreenCache()

        // Try CGEvent tap first — works in fullscreen Spaces
        let eventMask: CGEventMask = (1 << CGEventType.mouseMoved.rawValue)

        print("HotCornerMonitor: starting monitoring...")
        if let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<HotCornerMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleCGEvent(event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) {
            print("HotCornerMonitor: CGEvent tap created successfully")
            eventTap = tap
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            if let source = runLoopSource {
                CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            }
            CGEvent.tapEnable(tap: tap, enable: true)
        } else {
            print("HotCornerMonitor: CGEvent tap failed, check Accessibility permissions")
        }

        // Always also add NSEvent monitor as backup (works when app is in background but not fullscreen)
        nsEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.handleNSEventMouse()
        }
        print("HotCornerMonitor: NSEvent fallback monitor added")

        // Listen for screen config changes to update cache
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.updateScreenCache()
        }
    }

    private func stopMonitoring() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            runLoopSource = nil
            eventTap = nil
        }
        if let monitor = nsEventMonitor {
            NSEvent.removeMonitor(monitor)
            nsEventMonitor = nil
        }
        NotificationCenter.default.removeObserver(self, name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    private func handleCGEvent(_ event: CGEvent) {
        let cgPoint = event.location
        // Convert CG coordinates (top-left origin) to NS coordinates (bottom-left origin)
        let mouseLocation = NSPoint(x: cgPoint.x, y: cachedPrimaryHeight - cgPoint.y)

        for entry in cachedScreenCorners {
            if entry.corner.contains(mouseLocation) {
                triggerIfCooldownPassed()
                return
            }
        }
    }

    private func handleNSEventMouse() {
        let mouseLocation = NSEvent.mouseLocation
        for entry in cachedScreenCorners {
            if entry.corner.contains(mouseLocation) {
                triggerIfCooldownPassed()
                return
            }
        }
    }

    private func triggerIfCooldownPassed() {
        let now = Date()
        if now.timeIntervalSince(lastTriggerTime) >= cooldown {
            lastTriggerTime = now
            print("HotCornerMonitor: TRIGGERED! dispatching onTrigger")
            DispatchQueue.main.async { [weak self] in
                self?.onTrigger?()
            }
        }
    }
}
