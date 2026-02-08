//
//  AddressBarView.swift
//  SwiftBrowser
//

import SwiftUI

struct AddressBarView: View {
    @Binding var urlText: String
    @Binding var shouldFocus: Bool
    var isSecure: Bool
    var isLoading: Bool
    var onCommit: (String) -> Void
    var onReload: () -> Void

    @FocusState private var isFocused: Bool

    private var displayURL: String {
        // Show a cleaner URL when not focused
        if let url = URL(string: urlText), let host = url.host {
            return host + (url.path == "/" ? "" : url.path)
        }
        return urlText
    }

    var body: some View {
        HStack(spacing: 8) {
            // Security indicator
            Image(systemName: isSecure ? "lock.fill" : "globe")
                .foregroundStyle(isSecure ? .green : .secondary)
                .font(.system(size: 11, weight: .medium))
                .frame(width: 14)

            // URL text field
            TextField("Search or enter URL", text: $urlText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
                .onSubmit {
                    onCommit(urlText)
                }

            // Loading / Reload button
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 16, height: 16)
            } else {
                Button {
                    onReload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
        }
        .frame(minWidth: 240, maxWidth: 560)
        .onChange(of: shouldFocus) { _, newValue in
            if newValue {
                shouldFocus = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isFocused = true
                    // Force AppKit first responder as fallback for toolbar text fields
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let window = NSApp.keyWindow {
                            Self.focusToolbarTextField(in: window)
                        }
                    }
                }
            }
        }
    }

    private static func focusToolbarTextField(in window: NSWindow) {
        guard let toolbarView = window.toolbar?.items
            .compactMap({ $0.view })
            .first(where: { containsTextField($0) }) else { return }
        if let textField = findTextField(in: toolbarView) {
            window.makeFirstResponder(textField)
        }
    }

    private static func containsTextField(_ view: NSView) -> Bool {
        if view is NSTextField { return true }
        return view.subviews.contains { containsTextField($0) }
    }

    private static func findTextField(in view: NSView) -> NSTextField? {
        if let tf = view as? NSTextField, tf.isEditable { return tf }
        for subview in view.subviews {
            if let tf = findTextField(in: subview) { return tf }
        }
        return nil
    }
}
