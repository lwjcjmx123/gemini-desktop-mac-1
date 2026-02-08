//
//  SidebarView.swift
//  SwiftBrowser
//

import SwiftUI

struct SidebarView: View {
    @Bindable var tabManager: TabManager
    @State private var hoveredTabID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(tabManager.tabs) { tab in
                        let isSelected = tabManager.selectedTabID == tab.id
                        let isHovered = hoveredTabID == tab.id

                        SidebarTabRow(tab: tab, isSelected: isSelected)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isSelected
                                          ? Color.accentColor.opacity(0.15)
                                          : isHovered
                                            ? Color.primary.opacity(0.05)
                                            : Color.clear)
                            )
                            .onTapGesture {
                                tabManager.selectedTabID = tab.id
                            }
                            .onHover { hovering in
                                hoveredTabID = hovering ? tab.id : nil
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    tabManager.closeTab(tab.id)
                                } label: {
                                    Label("Close Tab", systemImage: "xmark")
                                }
                            }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }

            Divider()

            Button {
                tabManager.createTab()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("New Tab")
                        .font(.system(size: 13))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .background(.clear)
    }
}

struct SidebarTabRow: View {
    let tab: BrowserTab
    let isSelected: Bool

    private var domain: String {
        if let url = URL(string: tab.url), let host = url.host {
            return host
        }
        return ""
    }

    private var faviconName: String {
        if domain.contains("google") {
            return "g.circle.fill"
        } else if domain.contains("claude") || domain.contains("anthropic") {
            return "brain.head.profile"
        } else {
            return "globe"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: faviconName)
                .font(.system(size: 15))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title.isEmpty ? "New Tab" : tab.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .primary)
                    .lineLimit(1)
                if !domain.isEmpty {
                    Text(domain)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
