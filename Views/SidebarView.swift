//
//  SidebarView.swift
//  SwiftBrowser
//

import SwiftUI

struct SidebarView: View {
    @Bindable var tabManager: TabManager
    @Binding var isCollapsed: Bool
    var onNewTab: () -> Void
    @State private var hoveredTabID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            sidebarHeader
            tabList
        }
        .background(sidebarBackground)
    }

    private var sidebarHeader: some View {
        Group {
            if isCollapsed {
                // Collapsed: vertical stack of toggle and new tab buttons
                VStack(spacing: 4) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCollapsed.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.leading")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Expand Sidebar")

                    Button {
                        onNewTab()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("New Tab")
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
            } else {
                // Expanded: horizontal row with toggle on left, new tab on right
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCollapsed.toggle()
                        }
                    } label: {
                        Image(systemName: "sidebar.leading")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Collapse Sidebar")

                    Spacer()

                    Button {
                        onNewTab()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("New Tab")
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
        }
    }

    private var tabList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(tabManager.tabs) { tab in
                    SidebarTabRow(
                        tab: tab,
                        isSelected: tabManager.selectedTabID == tab.id,
                        isHovered: hoveredTabID == tab.id,
                        isCollapsed: isCollapsed,
                        onSelect: {
                            tabManager.selectedTabID = tab.id
                        },
                        onClose: {
                            tabManager.closeTab(tab.id)
                        }
                    )
                    .onHover { hovering in
                        hoveredTabID = hovering ? tab.id : nil
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
        }
    }

    private var sidebarBackground: some View {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(white: 0.12, alpha: 1.0)
            } else {
                return NSColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
            }
        })
    }
}

struct SidebarTabRow: View {
    let tab: BrowserTab
    let isSelected: Bool
    let isHovered: Bool
    let isCollapsed: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    private var titleDisplay: String {
        tab.title.isEmpty ? "New Tab" : tab.title
    }

    private var fallbackIcon: String {
        if let url = URL(string: tab.url), let host = url.host {
            if host.contains("google") { return "g.circle.fill" }
            if host.contains("claude") || host.contains("anthropic") { return "brain.head.profile" }
        }
        return "globe"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar for selected tab (Edge-style)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isSelected ? Color.accentColor : Color.clear)
                .frame(width: 3, height: 18)
                .padding(.trailing, isCollapsed ? 0 : 6)

            // Favicon
            Group {
                if let image = tab.webViewModel.faviconImage {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: fallbackIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
            }
            .frame(width: 16, height: 16)

            if !isCollapsed {
                // Title only (no domain subtitle -- matches Edge)
                Text(titleDisplay)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.leading, 8)

                Spacer(minLength: 4)

                // Close button -- visible only on hover (Edge-style)
                if isHovered {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: 20)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.primary.opacity(0.08))
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, isCollapsed ? 4 : 6)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected
                      ? Color.primary.opacity(0.08)
                      : isHovered
                        ? Color.primary.opacity(0.04)
                        : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button(role: .destructive) {
                onClose()
            } label: {
                Label("Close Tab", systemImage: "xmark")
            }
        }
        .help(isCollapsed ? titleDisplay : "")
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
