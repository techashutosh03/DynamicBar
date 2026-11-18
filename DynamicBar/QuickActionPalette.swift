//
//  QuickActionPalette.swift
//  DynamicBar
//

import AppKit
import Combine
import SwiftUI

struct QuickAction: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let keywords: [String]
    let perform: @MainActor () -> Void

    init(
        id: String,
        title: String,
        subtitle: String = "",
        systemImage: String = "sparkles",
        keywords: [String] = [],
        perform: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.keywords = keywords
        self.perform = perform
    }

    var searchableText: String {
        ([title, subtitle] + keywords)
            .joined(separator: " ")
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            )
    }
}

@MainActor
final class QuickActionStore: ObservableObject {
    @Published var query = "" {
        didSet { selectedIndex = 0 }
    }

    @Published private(set) var actions: [QuickAction] = []
    @Published private(set) var selectedIndex = 0
    @Published private(set) var isPresented = false

    var onDismiss: (() -> Void)?

    var filteredActions: [QuickAction] {
        let normalizedQuery = query.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )

        let terms = normalizedQuery
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        guard !terms.isEmpty else {
            return actions
        }

        return actions.filter { action in
            terms.allSatisfy { action.searchableText.contains($0) }
        }
    }

    func register(_ action: QuickAction) {
        if let index = actions.firstIndex(where: { $0.id == action.id }) {
            actions[index] = action
        } else {
            actions.append(action)
        }
    }

    func moveSelection(by offset: Int) {
        let count = filteredActions.count
        guard count > 0 else {
            selectedIndex = 0
            return
        }

        selectedIndex = (selectedIndex + offset + count) % count
    }

    func select(_ index: Int) {
        guard filteredActions.indices.contains(index) else { return }
        selectedIndex = index
    }

    func runSelected() {
        let matches = filteredActions
        guard matches.indices.contains(selectedIndex) else { return }
        run(matches[selectedIndex])
    }

    func run(_ action: QuickAction) {
        dismiss()
        action.perform()
    }

    func prepareForPresentation() {
        query = ""
        selectedIndex = 0
        isPresented = true
    }

    func dismiss() {
        guard isPresented else { return }

        isPresented = false
        query = ""
        selectedIndex = 0
        onDismiss?()
    }
}

@MainActor
struct QuickActionPaletteView: View {
    @ObservedObject var store: QuickActionStore

    @FocusState private var searchFieldFocused: Bool
    @State private var keyboardMonitor: Any?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search actions…", text: $store.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .focused($searchFieldFocused)
                    .onSubmit {
                        store.runSelected()
                    }

                Text("ESC")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)

            Divider()

            resultsView

            Divider()

            HStack {
                Text("\(store.filteredActions.count) actions")
                Spacer()
                Text("↑ ↓ Navigate   ↵ Run   Esc Close")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
        .frame(width: 560, height: 420)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 25, x: 0, y: 12)
        .onAppear {
            installKeyboardMonitor()
            focusSearchField()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .onReceive(store.$isPresented) { isPresented in
            if isPresented {
                focusSearchField()
            }
        }
    }

    private var resultsView: some View {
        let matches = store.filteredActions

        return Group {
            if matches.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)

                    Text(store.actions.isEmpty ? "No actions registered" : "No matching actions")
                        .font(.system(size: 14, weight: .medium))

                    Text(store.actions.isEmpty
                         ? "Register actions to show them here."
                         : "Try a different search.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(matches.enumerated()), id: \.element.id) { row in
                            actionRow(row.element, index: row.offset)
                        }
                    }
                    .padding(8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func actionRow(_ action: QuickAction, index: Int) -> some View {
        Button {
            store.run(action)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.primary.opacity(0.07)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(action.title)
                        .font(.system(size: 13, weight: .medium))

                    if !action.subtitle.isEmpty {
                        Text(action.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if index == store.selectedIndex {
                    Text("↵")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        index == store.selectedIndex
                            ? Color.accentColor.opacity(0.18)
                            : Color.clear
                    )
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            if isHovering {
                store.select(index)
            }
        }
    }

    private func focusSearchField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            searchFieldFocused = true
        }
    }

    private func installKeyboardMonitor() {
        guard keyboardMonitor == nil else { return }

        let actionStore = store

        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard actionStore.isPresented else { return event }

            switch event.keyCode {
            case 126: // Up arrow
                actionStore.moveSelection(by: -1)
                return nil
            case 125: // Down arrow
                actionStore.moveSelection(by: 1)
                return nil
            case 36, 76: // Return or keypad Enter
                actionStore.runSelected()
                return nil
            case 53: // Escape
                actionStore.dismiss()
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyboardMonitor() {
        guard let keyboardMonitor else { return }
        NSEvent.removeMonitor(keyboardMonitor)
        self.keyboardMonitor = nil
    }
}

@MainActor
private final class KeyablePalettePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class QuickActionPaletteController: NSObject, NSWindowDelegate {
    private let store: QuickActionStore
    private var panel: KeyablePalettePanel?

    init(store: QuickActionStore) {
        self.store = store
        super.init()

        store.onDismiss = { [weak self] in
            self?.panel?.orderOut(nil)
        }
    }

    func toggle() {
        if store.isPresented {
            store.dismiss()
        } else {
            show()
        }
    }

    func show() {
        if panel == nil {
            panel = makePanel()
        }

        guard let panel else { return }

        store.prepareForPresentation()

        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first {
            $0.frame.contains(mouseLocation)
        } ?? NSScreen.main

        let visibleFrame = screen?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let width: CGFloat = 560
        let height: CGFloat = 420
        let y = max(visibleFrame.minY + 20, visibleFrame.maxY - height - 90)

        panel.setFrame(
            NSRect(
                x: visibleFrame.midX - width / 2,
                y: y,
                width: width,
                height: height
            ),
            display: false
        )

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        guard
            let panel,
            let window = notification.object as? NSWindow,
            window === panel,
            store.isPresented
        else {
            return
        }

        store.dismiss()
    }

    private func makePanel() -> KeyablePalettePanel {
        let panel = KeyablePalettePanel(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.title = "Quick Actions"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: QuickActionPaletteView(store: store)
        )
        panel.setContentSize(NSSize(width: 560, height: 420))

        return panel
    }
}

@MainActor
enum DynamicBarQuickActions {
    static let store = QuickActionStore()
    static let palette = QuickActionPaletteController(store: store)
}

@MainActor
struct DynamicBarQuickActionCommands: Commands {
    var body: some Commands {
        CommandMenu("DynamicBar") {
            Button("Quick Actions…") {
                DynamicBarQuickActions.palette.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
        }
    }
}

@MainActor
func installQuickActions() {
    // Developer Server Probes
    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "developer.open-vite",
            title: "Open localhost:5173",
            subtitle: "Open the Vite development server",
            systemImage: "network",
            keywords: ["vite", "server", "localhost", "5173", "dev"]
        ) {
            guard let url = URL(string: "http://localhost:5173") else { return }
            NSWorkspace.shared.open(url)
        }
    )

    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "developer.open-3000",
            title: "Open localhost:3000",
            subtitle: "Open local Node / Next.js server",
            systemImage: "network",
            keywords: ["node", "next", "react", "server", "localhost", "3000"]
        ) {
            guard let url = URL(string: "http://localhost:3000") else { return }
            NSWorkspace.shared.open(url)
        }
    )

    // Developer Eyedropper
    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "developer.eyedropper",
            title: "Pick Screen Color (Eyedropper)",
            subtitle: "Sample screen pixel and copy hex code to clipboard",
            systemImage: "eyedropper",
            keywords: ["eyedropper", "color", "picker", "hex", "design"]
        ) {
            DeveloperColorPicker().pickColor()
        }
    )

    // Focus Timer
    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "focus.start25",
            title: "Start Focus Session (25m)",
            subtitle: "Begin a 25-minute Pomodoro focus timer",
            systemImage: "timer",
            keywords: ["focus", "pomodoro", "timer", "work"]
        ) {
            FocusTimerModel.shared.start(minutes: 25)
        }
    )

    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "focus.toggle",
            title: "Pause / Resume Focus Timer",
            subtitle: "Toggle the current focus timer",
            systemImage: "pause.circle",
            keywords: ["focus", "pause", "resume", "timer"]
        ) {
            FocusTimerModel.shared.toggle()
        }
    )

    // Meeting Quick Join
    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "meeting.join",
            title: "Join Upcoming Meeting",
            subtitle: "Open video link for next scheduled meeting",
            systemImage: "video.fill",
            keywords: ["meeting", "zoom", "meet", "teams", "call", "video"]
        ) {
            let store = MeetingStore()
            Task { @MainActor in
                await store.refresh()
                if let url = store.nextMeeting?.joinURL {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    )

    // Media Controls
    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "media.playpause",
            title: "Play / Pause Music",
            subtitle: "Toggle music playback",
            systemImage: "playpause.fill",
            keywords: ["music", "media", "play", "pause", "song", "spotify", "apple music"]
        ) {
            MusicManager.shared.playPause()
        }
    )

    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "media.next",
            title: "Next Track",
            subtitle: "Skip to next song",
            systemImage: "forward.fill",
            keywords: ["music", "media", "next", "track", "skip"]
        ) {
            MusicManager.shared.nextTrack()
        }
    )

    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "media.previous",
            title: "Previous Track",
            subtitle: "Go to previous song",
            systemImage: "backward.fill",
            keywords: ["music", "media", "previous", "track", "back"]
        ) {
            MusicManager.shared.previousTrack()
        }
    )

    // Camera / Mirror
    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "camera.toggle",
            title: "Toggle Camera Mirror",
            subtitle: "Start or stop camera preview",
            systemImage: "web.camera",
            keywords: ["camera", "mirror", "webcam", "video", "face"]
        ) {
            let webcam = WebcamManager.shared
            if webcam.isSessionRunning {
                webcam.stopSession()
            } else {
                webcam.startSession()
            }
        }
    )

    // File Shelf
    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "shelf.show",
            title: "Show Dynamic Shelf",
            subtitle: "Open the drag & drop file shelf",
            systemImage: "books.vertical",
            keywords: ["shelf", "files", "airdrop", "drag", "drop"]
        ) {
            DynamicBarViewCoordinator.shared.currentView = .shelf
        }
    )

    // Settings & System
    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "settings.open",
            title: "Open Settings",
            subtitle: "Configure DynamicBar preferences and shortcuts",
            systemImage: "gearshape",
            keywords: ["settings", "preferences", "config", "options"]
        ) {
            SettingsWindowController.shared.showWindow()
        }
    )

    DynamicBarQuickActions.store.register(
        QuickAction(
            id: "system.restart",
            title: "Restart DynamicBar",
            subtitle: "Relaunch DynamicBar",
            systemImage: "arrow.clockwise",
            keywords: ["restart", "relaunch", "app"]
        ) {
            ApplicationRelauncher.restart()
        }
    )
}
