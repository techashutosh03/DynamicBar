//
//  BluetoothMonitor.swift
//  DynamicBar
//

import Combine
import Foundation
import IOBluetooth

struct ConnectedBluetoothDevice: Identifiable, Hashable {
    let id: String
    let name: String
}

@MainActor
final class BluetoothMonitor: ObservableObject {
    @Published private(set) var devices: [ConnectedBluetoothDevice] = []

    var onConnectionChange: ((ConnectedBluetoothDevice, Bool) -> Void)?

    private var timer: Timer?
    private var previous: [String: ConnectedBluetoothDevice] = [:]

    func start() {
        guard timer == nil else { return }

        refresh()

        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []

        let connected = paired
            .filter { $0.isConnected() }
            .map { device in
                let name = device.name ?? "Bluetooth device"
                let address = device.addressString ?? name

                return ConnectedBluetoothDevice(id: address, name: name)
            }

        let current = Dictionary(
            uniqueKeysWithValues: connected.map { ($0.id, $0) }
        )

        for (id, device) in current where previous[id] == nil {
            onConnectionChange?(device, true)
        }

        for (id, device) in previous where current[id] == nil {
            onConnectionChange?(device, false)
        }

        previous = current
        devices = connected.sorted { $0.name < $1.name }
    }
}
