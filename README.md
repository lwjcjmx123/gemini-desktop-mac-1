# Swift Browser

A lightweight, native macOS browser built with Swift and WKWebView. No Electron, no Node.js — just a fast, minimal browsing experience.

## Features

- **Tabbed Browsing** — Multiple tabs with a sidebar, tab persistence across restarts
- **Address Bar** — Enter URLs, domain names, or search queries (Google Search)
- **Global Keyboard Shortcut** — Configurable shortcut to toggle the browser window from any app
- **Hot Corner Trigger** — Show/hide the browser by moving the mouse to the bottom-left corner (works in fullscreen)
- **Menu Bar Extra** — Quick access from the system tray
- **SOCKS5 / HTTP Proxy** — Built-in proxy support via macOS Network framework
- **IME Support** — Fixes double-Enter issue for CJK input methods
- **File Downloads** — Download files directly to your Downloads folder
- **Adjustable Text Size** — Zoom from 60% to 140%
- **Launch at Login** — Optional auto-start with macOS
- **Hide Dock Icon** — Run as a menu bar-only app
- **Privacy** — No tracking, no data collection. Reset all website data with one click.

## System Requirements

- **macOS 14.0 (Sonoma)** or later

## Build from Source

```bash
git clone <repo-url>
cd swift-browser
open GeminiDesktop.xcodeproj
# Build and run with Cmd+R in Xcode
```

Or use the build script:

```bash
./scripts/build.sh          # Build only
./scripts/build.sh --open   # Build and open
./scripts/build.sh --dmg    # Build and create DMG
./scripts/build.sh --release # Release configuration
```

## Architecture

- **Language:** Swift 5.0
- **UI:** SwiftUI + AppKit interop
- **Web Engine:** WKWebView
- **Dependency:** [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (via SPM)

### Project Structure

```
App/            — Entry point (SwiftBrowserApp) and AppDelegate
Coordinators/   — AppCoordinator (central state manager)
Models/         — BrowserTab, TabManager
WebKit/         — WebViewModel, BrowserWebView, WebViewFactory, UserScripts
Views/          — MainWindowView, SidebarView, AddressBarView, MenuBarView, SettingsView
Utils/          — UserDefaultsKeys, NSScreen extensions, HotCornerMonitor, ProxyHelper, KeyboardShortcutNames
Resources/      — App icon, entitlements, Info.plist
scripts/        — Build and DMG packaging scripts
```

## License

[MIT](LICENSE)
