# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gemini Desktop is an unofficial native macOS desktop wrapper for Google Gemini (`https://gemini.google.com/app`). It loads the official Gemini website inside a `WKWebView` to provide a desktop-class experience. No Electron, no Node.js — this is a pure Swift/Xcode project.

- **Bundle ID:** `com.alexcding.geminidesktop`
- **Minimum macOS:** 14.0 (Sonoma)
- **Language:** Swift 5.0
- **UI:** SwiftUI + AppKit interop
- **Single dependency:** [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) v2.0.0+ via Swift Package Manager

## Build & Run

```bash
# Open in Xcode and build with Cmd+R
open GeminiDesktop.xcodeproj

# Create DMG for distribution (expects built .app at ~/Downloads/GeminiDesktop/)
./scripts/create-dmg.sh
```

There are no tests in this project. The Xcode scheme has a TestAction but no test targets exist.

## Architecture

### Single Shared WKWebView

The most important architectural decision: there is exactly **one** `WKWebView` instance, owned by `WebViewModel`. It is physically moved between the main window and the floating chat bar panel via `WebViewContainer.attachWebView()` (triggered by `NSWindow.didBecomeKeyNotification`). This avoids duplicate sessions/logins but means the WebView can only be in one view hierarchy at a time.

### Coordinator Pattern

`AppCoordinator` is the central state hub. All views bind to it via `@Binding`. It manages:
- Navigation (back/forward/home/reload) — delegated to `WebViewModel`
- Zoom level — persisted to `UserDefaults`
- Chat bar visibility — owns the `ChatBarPanel` instance
- Window lifecycle — finding, showing, hiding, and positioning windows

### SwiftUI + AppKit Hybrid

The app uses SwiftUI for declarative scene definitions (`Window`, `Settings`, `MenuBarExtra`) but drops into AppKit for:
- `ChatBarPanel` — an `NSPanel` subclass (floating, always-on-top, borderless, resizable)
- `WebViewContainer` — an `NSView` subclass that hosts the shared `WKWebView` via `NSViewRepresentable`
- Window management — finding windows by identifier, positioning on screens

### Three UI Surfaces

1. **Main Window** (`MainWindowView`) — full desktop window with toolbar (back button + minimize-to-chat-bar button)
2. **Chat Bar** (`ChatBarPanel` + `ChatBarView`) — floating `NSPanel` that auto-expands when a conversation is detected (polls via JS every 1s)
3. **Menu Bar Extra** (`MenuBarView`) — system tray dropdown with Open/Toggle Chat Bar/Settings/Quit

### Injected JavaScript (`UserScripts`)

Two scripts are injected into the WebView:
- **IME fix** (always) — resolves double-Enter issue for CJK input method editors by intercepting `compositionend` events and auto-clicking the send button
- **Console log bridge** (DEBUG only) — forwards `console.log` to native Swift via `WKScriptMessageHandler`

### Key Patterns

- **Constants** are defined as nested `Constants` structs within extensions of each type (e.g., `ChatBarPanel.Constants`, `GeminiWebView.Constants`)
- **UserDefaults keys** are centralized in `UserDefaultsKeys` enum (`Utils/UserDefaultsKeys.swift`)
- **Screen utilities** (`NSScreen+Extensions.swift`) handle multi-monitor positioning — finding the screen at mouse location, centering windows, bottom-center positioning for the chat bar
- **External URL detection** (`GeminiWebView.Coordinator.isExternalURL`) keeps `gemini.google.com`, `accounts.google.com`, `*.googleapis.com`, and `*.gstatic.com` in-app; everything else opens in the default browser

## Directory Layout

```
App/            — @main entry point (GeminiDesktopApp) and AppDelegate
Coordinators/   — AppCoordinator (central state manager)
ChatBar/        — ChatBarPanel (NSPanel) and ChatBarView (SwiftUI overlay)
WebKit/         — WebViewModel, GeminiWebView (NSViewRepresentable), UserScripts
Views/          — MainWindowView, MenuBarView, SettingsView
Utils/          — UserDefaultsKeys, NSScreen extensions
scripts/        — create-dmg.sh (DMG packaging)
```
