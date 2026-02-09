//
//  HistoryView.swift
//  SwiftBrowser
//

import SwiftUI

struct HistoryView: View {
    @State private var searchText = ""
    @State private var showingClearAlert = false
    var onNavigate: ((String) -> Void)?

    private var historyManager: HistoryManager { HistoryManager.shared }

    private var filteredGroups: [(String, [HistoryItem])] {
        if searchText.isEmpty {
            return historyManager.groupedByDate()
        } else {
            let results = historyManager.search(searchText)
            return historyManager.groupedByDate(results)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("History")
                    .font(.title2.bold())
                Spacer()
                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Text("Clear All")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(historyManager.items.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            Divider()

            // History list
            if filteredGroups.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundStyle(.quaternary)
                    Text(searchText.isEmpty ? "No browsing history" : "No results found")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                List {
                    ForEach(filteredGroups, id: \.0) { dateLabel, items in
                        Section(dateLabel) {
                            ForEach(items) { item in
                                HistoryRow(item: item)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onNavigate?(item.url)
                                    }
                                    .contextMenu {
                                        Button {
                                            onNavigate?(item.url)
                                        } label: {
                                            Label("Open", systemImage: "arrow.right")
                                        }
                                        Button {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(item.url, forType: .string)
                                        } label: {
                                            Label("Copy URL", systemImage: "doc.on.doc")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            historyManager.removeItems([item.id])
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .alert("Clear All History?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                historyManager.clearAll()
            }
        } message: {
            Text("This will permanently delete all browsing history.")
        }
    }
}

struct HistoryRow: View {
    let item: HistoryItem

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: faviconName)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text(item.url)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(Self.timeFormatter.string(from: item.timestamp))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var faviconName: String {
        let domain = item.domain
        if domain.contains("google") {
            return "g.circle.fill"
        } else if domain.contains("claude") || domain.contains("anthropic") {
            return "brain.head.profile"
        } else {
            return "globe"
        }
    }
}
