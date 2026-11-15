//
//  DeveloperTools.swift
//  DynamicBar
//

import AppKit
import Combine
import Foundation
import Network
import SwiftUI

private final class TCPPortProbe {
    private let connection: NWConnection
    private let queue = DispatchQueue(label: "DynamicBar.TCPPortProbe")
    private let completion: (Bool) -> Void
    private let lock = NSLock()
    private var finished = false

    init?(port: UInt16, completion: @escaping (Bool) -> Void) {
        guard let networkPort = NWEndpoint.Port(rawValue: port) else {
            return nil
        }

        self.completion = completion
        self.connection = NWConnection(
            host: NWEndpoint.Host("127.0.0.1"),
            port: networkPort,
            using: .tcp
        )
    }

    func start() {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.finish(true)
            case .failed(_), .cancelled:
                self?.finish(false)
            default:
                break
            }
        }

        connection.start(queue: queue)

        queue.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.finish(false)
        }
    }

    func cancel() {
        finish(false)
    }

    private func finish(_ isOpen: Bool) {
        lock.lock()
        guard !finished else {
            lock.unlock()
            return
        }
        finished = true
        lock.unlock()

        connection.cancel()
        completion(isOpen)
    }
}

@MainActor
final class DeveloperServerScanner: ObservableObject {
    @Published private(set) var openPorts: [UInt16] = []

    private let candidatePorts: [UInt16] = [
        3000, 3001, 4000, 4200, 5000, 5173, 8000, 8080, 8787
    ]

    private var probes: [UInt16: TCPPortProbe] = [:]
    private var scanGeneration = 0

    func scan() {
        scanGeneration += 1
        let generation = scanGeneration

        probes.values.forEach { $0.cancel() }
        probes.removeAll()
        openPorts.removeAll()

        for port in candidatePorts {
            guard let probe = TCPPortProbe(port: port, completion: { [weak self] isOpen in
                Task { @MainActor [weak self] in
                    guard let self, self.scanGeneration == generation else {
                        return
                    }

                    self.probes[port] = nil

                    if isOpen && !self.openPorts.contains(port) {
                        self.openPorts.append(port)
                        self.openPorts.sort()
                    }
                }
            }) else {
                continue
            }

            probes[port] = probe
            probe.start()
        }
    }

    func openInBrowser(port: UInt16) {
        guard openPorts.contains(port),
              let url = URL(string: "http://127.0.0.1:\(port)")
        else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

@MainActor
final class DeveloperColorPicker: ObservableObject {
    @Published private(set) var selectedHex: String?

    func pickColor() {
        NSColorSampler().show { [weak self] color in
            guard let rgb = color?.usingColorSpace(.deviceRGB) else { return }

            let hex = String(
                format: "#%02X%02X%02X",
                Int((rgb.redComponent * 255).rounded()),
                Int((rgb.greenComponent * 255).rounded()),
                Int((rgb.blueComponent * 255).rounded())
            )

            Task { @MainActor in
                self?.selectedHex = hex
            }
        }
    }

    func copyHex() {
        guard let selectedHex else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedHex, forType: .string)
    }
}

struct DeveloperPillView: View {
    @StateObject private var scanner = DeveloperServerScanner()
    @StateObject private var colorPicker = DeveloperColorPicker()

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { scanner.scan() }) {
                Image(systemName: "network")
            }
            .buttonStyle(.plain)
            .help("Scan local development ports")

            ForEach(scanner.openPorts, id: \.self) { port in
                Button(":\(port)") {
                    scanner.openInBrowser(port: port)
                }
                .buttonStyle(.plain)
                .help("Open http://127.0.0.1:\(port)")
            }

            Divider().frame(height: 12)

            Button(action: { colorPicker.pickColor() }) {
                Image(systemName: "eyedropper")
            }
            .buttonStyle(.plain)
            .help("Pick screen color")

            if let hex = colorPicker.selectedHex {
                Button(hex) {
                    colorPicker.copyHex()
                }
                .buttonStyle(.plain)
                .help("Click to copy hex to clipboard")
            }
        }
        .font(.system(size: 11, weight: .medium))
        .onAppear {
            scanner.scan()
        }
    }
}
