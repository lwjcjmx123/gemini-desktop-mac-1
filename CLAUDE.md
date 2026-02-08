# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Swift Browser is a lightweight native macOS browser built with Swift and WKWebView. It provides tabbed browsing, an address bar, proxy support, and system integration features like hot corner triggers and global keyboard shortcuts.

- **Bundle ID:** `com.swiftbrowser.browser`
- **Minimum macOS:** 14.0 (Sonoma)
- **Language:** Swift 5.0
- **UI:** SwiftUI + AppKit interop
- **Single dependency:** [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) v2.0.0+ via Swift Package Manager

## Build & Run

```bash
# Open in Xcode and build with Cmd+R
open GeminiDesktop.xcodeproj

# Or use the build script
./scripts/build.sh          # Build only
./scripts/build.sh --open   # Build and open
./scripts/build.sh --dmg    # Build and create DMG
```

There are no tests in this project.

## Architecture

### Tabbed Browsing

Each tab is a `BrowserTab` instance that owns its own `WebViewModel` (which in turn owns a `WKWebView`). Tabs are managed by `TabManager`, which handles creation, closing, selection, and persistence to `UserDefaults`.

### Coordinator Pattern

`AppCoordinator` is the central state hub. All views bind to it via `@Binding`. It manages:
- Navigation (back/forward/home/reload) — delegated to the selected tab's `WebViewModel`
- Zoom level — persisted to `UserDefaults`
- Hot corner trigger — owns `HotCornerMonitor`, slides window in/out from bottom-left
- Global keyboard shortcut — via KeyboardShortcuts library
- Window lifecycle — finding, showing, hiding, and positioning windows
- Tab management — delegated to `TabManager`

### SwiftUI + AppKit Hybrid

The app uses SwiftUI for declarative scene definitions (`Window`, `Settings`, `MenuBarExtra`) but drops into AppKit for:
- `WebViewContainer` — an `NSView` subclass that hosts a `WKWebView` via `NSViewRepresentable`
- Window management — finding windows by identifier, positioning on screens, slide animations

### Two UI Surfaces

1. **Main Window** (`MainWindowView`) — full desktop window with sidebar (tabs), address bar, and toolbar (back/forward/new tab)
2. **Menu Bar Extra** (`MenuBarView`) — system tray dropdown with Open/Settings/Quit

### WebView Configuration (`WebViewFactory`)

`WebViewFactory` creates configured `WKWebView` instances with:
- Custom Safari user agent
- User scripts (IME fix, console log bridge)
- Optional SOCKS5/HTTP proxy via `ProxyHelper`
- Saved zoom level from `UserDefaults`

### Injected JavaScript (`UserScripts`)

Two scripts are injected into the WebView:
- **IME fix** (always) — resolves double-Enter issue for CJK input method editors by intercepting `compositionend` events and auto-clicking the send button
- **Console log bridge** (DEBUG only) — forwards `console.log` to native Swift via `WKScriptMessageHandler`

### Key Patterns

- **Constants** are defined as nested `Constants` structs within extensions of each type (e.g., `BrowserWebView.Constants`, `AppCoordinator.Constants`)
- **UserDefaults keys** are centralized in `UserDefaultsKeys` enum (`Utils/UserDefaultsKeys.swift`)
- **Screen utilities** (`NSScreen+Extensions.swift`) handle multi-monitor positioning — finding the screen at mouse location, centering windows
- **Hot corner** (`HotCornerMonitor`) uses CGEvent tap (works in fullscreen) with NSEvent fallback
- **External links** with `target="_blank"` are loaded in the current tab (no new window creation)

## Directory Layout

```
App/            — @main entry point (SwiftBrowserApp) and AppDelegate
Coordinators/   — AppCoordinator (central state manager)
Models/         — BrowserTab (tab model), TabManager (tab collection + persistence)
WebKit/         — WebViewModel, BrowserWebView (NSViewRepresentable), WebViewFactory, UserScripts
Views/          — MainWindowView, SidebarView, AddressBarView, MenuBarView, SettingsView
Utils/          — UserDefaultsKeys, NSScreen extensions, HotCornerMonitor, ProxyHelper, KeyboardShortcutNames
Resources/      — App icon, entitlements, Info.plist
scripts/        — build.sh (build + DMG), create-dmg.sh (DMG from DerivedData)
```
