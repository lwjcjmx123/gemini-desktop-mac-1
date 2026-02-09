//
//  SiteDataView.swift
//  SwiftBrowser
//

import SwiftUI
import WebKit

struct SiteDataView: View {
    @State private var records: [WKWebsiteDataRecord] = []
    @State private var searchText = ""
    @State private var selectedRecords: Set<String> = []
    @State private var isLoading = true
    @State private var showingClearAlert = false
    @State private var clearTarget: ClearTarget = .selected

    private enum ClearTarget {
        case selected
        case all
    }

    private var filteredRecords: [WKWebsiteDataRecord] {
        if searchText.isEmpty {
            return records
        }
        let q = searchText.lowercased()
        return records.filter { $0.displayName.lowercased().contains(q) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Site Data")
                    .font(.title2.bold())
                Spacer()
                Button(role: .destructive) {
                    clearTarget = .all
                    showingClearAlert = true
                } label: {
                    Text("Clear All")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(records.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField("Search sites...", text: $searchText)
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
            .padding(.bottom, 8)

            // Selection actions
            if !selectedRecords.isEmpty {
                HStack {
                    Text("\(selectedRecords.count) selected")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(role: .destructive) {
                        clearTarget = .selected
                        showingClearAlert = true
                    } label: {
                        Text("Clear Selected")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }

            Divider()

            // Site list
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredRecords.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundStyle(.quaternary)
                    Text(searchText.isEmpty ? "No site data stored" : "No results found")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                List(filteredRecords, id: \.displayName, selection: $selectedRecords) { record in
                    SiteDataRow(record: record)
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear { fetchRecords() }
        .alert(alertTitle, isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { performClear() }
        } message: {
            Text(alertMessage)
        }
    }

    private var alertTitle: String {
        clearTarget == .all ? "Clear All Site Data?" : "Clear Selected Site Data?"
    }

    private var alertMessage: String {
        clearTarget == .all
            ? "This will remove cookies, cache, and storage for all websites. You will need to sign in again."
            : "This will remove cookies, cache, and storage for the selected \(selectedRecords.count) site(s)."
    }

    private func fetchRecords() {
        isLoading = true
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: types) { fetched in
            DispatchQueue.main.async {
                self.records = fetched.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
                self.isLoading = false
            }
        }
    }

    private func performClear() {
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()

        let targetRecords: [WKWebsiteDataRecord]
        if clearTarget == .all {
            targetRecords = records
        } else {
            targetRecords = records.filter { selectedRecords.contains($0.displayName) }
        }

        guard !targetRecords.isEmpty else { return }

        dataStore.removeData(ofTypes: types, for: targetRecords) {
            DispatchQueue.main.async {
                self.selectedRecords.removeAll()
                self.fetchRecords()
            }
        }
    }
}

struct SiteDataRow: View {
    let record: WKWebsiteDataRecord

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: faviconName)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.displayName)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text(dataTypeSummary)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var faviconName: String {
        let name = record.displayName.lowercased()
        if name.contains("google") {
            return "g.circle.fill"
        } else if name.contains("claude") || name.contains("anthropic") {
            return "brain.head.profile"
        } else {
            return "globe"
        }
    }

    private var dataTypeSummary: String {
        let types = record.dataTypes
        var parts: [String] = []
        if types.contains(WKWebsiteDataTypeCookies) { parts.append("Cookies") }
        if types.contains(WKWebsiteDataTypeLocalStorage) { parts.append("LocalStorage") }
        if types.contains(WKWebsiteDataTypeSessionStorage) { parts.append("SessionStorage") }
        if types.contains(WKWebsiteDataTypeIndexedDBDatabases) { parts.append("IndexedDB") }
        if types.contains(WKWebsiteDataTypeDiskCache) || types.contains(WKWebsiteDataTypeMemoryCache) { parts.append("Cache") }
        if parts.isEmpty {
            // Show raw type count
            return "\(types.count) data type(s)"
        }
        return parts.joined(separator: ", ")
    }
}
