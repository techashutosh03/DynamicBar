//
//  ScreenshotWatcher.swift
//  DynamicBar
//

import AppKit
import Combine
import Foundation

@MainActor
final class ScreenshotWatcher: ObservableObject {
    @Published private(set) var isWatching = false

    // Connect this to your existing shelf-import method.
    var onNewScreenshot: ((URL) -> Void)?

    // Keep this false unless the user explicitly enables the setting.
    var copyScreenshotToClipboard = false

    private let bookmarkKey = "DynamicBar.ScreenshotFolderBookmark"
    private var folderURL: URL?
    private var hasSecurityScope = false
    private var scanTimer: Timer?
    private var knownPaths = Set<String>()

    func chooseFolderAndStart() throws {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Watch This Folder"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        let bookmark = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)

        startWatching(url)
    }

    func restoreSavedFolder() throws {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            let refreshed = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(refreshed, forKey: bookmarkKey)
        }

        startWatching(url)
    }

    func stopWatching() {
        scanTimer?.invalidate()
        scanTimer = nil

        if hasSecurityScope {
            folderURL?.stopAccessingSecurityScopedResource()
        }

        folderURL = nil
        hasSecurityScope = false
        isWatching = false
    }

    private func startWatching(_ folder: URL) {
        stopWatching()

        hasSecurityScope = folder.startAccessingSecurityScopedResource()
        folderURL = folder
        knownPaths = Set(screenshotFiles(in: folder).map(\.path))
        isWatching = true

        scanTimer = Timer.scheduledTimer(
            withTimeInterval: 2,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.scan()
            }
        }
    }

    private func scan() {
        guard let folderURL else { return }

        for file in screenshotFiles(in: folderURL) {
            guard knownPaths.insert(file.path).inserted else { continue }

            // Wait briefly for macOS to finish writing the screenshot.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                Task { @MainActor in
                    guard let self,
                          FileManager.default.fileExists(atPath: file.path),
                          let attributes = try? FileManager.default.attributesOfItem(
                              atPath: file.path
                          ),
                          let size = attributes[.size] as? NSNumber,
                          size.intValue > 0
                    else {
                        return
                    }

                    if self.copyScreenshotToClipboard,
                       let image = NSImage(contentsOf: file) {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.writeObjects([image])
                    }

                    self.onNewScreenshot?(file)
                }
            }
        }
    }

    private func screenshotFiles(in folder: URL) -> [URL] {
        let allowedExtensions = ["png", "jpg", "jpeg", "heic"]

        let files = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        return files.filter { url in
            let name = url.deletingPathExtension().lastPathComponent.lowercased()
            let ext = url.pathExtension.lowercased()

            return (name.hasPrefix("screenshot") || name.hasPrefix("screen shot"))
                && allowedExtensions.contains(ext)
        }
    }

    /// Convenience method to connect to Shelf import
    func configureDefaultShelfImport() {
        self.onNewScreenshot = { fileURL in
            Task { @MainActor in
                if let bookmark = try? Bookmark(url: fileURL) {
                    let item = ShelfItem(kind: .file(bookmark: bookmark.data))
                    ShelfStateViewModel.shared.add([item])
                }
            }
        }
    }
}

