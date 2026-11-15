//
//  FocusTimer.swift
//  DynamicBar
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class FocusTimerModel: ObservableObject {
    @Published private(set) var duration: TimeInterval = 25 * 60
    @Published private(set) var remaining: TimeInterval = 25 * 60
    @Published private(set) var isRunning = false

    private var endDate: Date?
    private var timer: Timer?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return 1 - remaining / duration
    }

    var formattedTime: String {
        let seconds = max(0, Int(remaining))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    func start(minutes: Int = 25) {
        timer?.invalidate()

        duration = TimeInterval(max(1, minutes) * 60)
        remaining = duration
        endDate = Date().addingTimeInterval(remaining)
        isRunning = true

        startTicking()
    }

    func pause() {
        updateRemaining()
        timer?.invalidate()
        timer = nil
        endDate = nil
        isRunning = false
    }

    func resume() {
        guard remaining > 0 else {
            start(minutes: 25)
            return
        }

        endDate = Date().addingTimeInterval(remaining)
        isRunning = true
        startTicking()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        endDate = nil
        isRunning = false
        remaining = duration
    }

    func toggle() {
        isRunning ? pause() : resume()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                self?.updateRemaining()
            }
        }
    }

    private func updateRemaining() {
        guard let endDate else { return }

        remaining = max(0, endDate.timeIntervalSinceNow)

        if remaining == 0 {
            timer?.invalidate()
            timer = nil
            self.endDate = nil
            isRunning = false
        }
    }
}

struct FocusTimerPill: View {
    @ObservedObject var model: FocusTimerModel

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.35), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: model.progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 18, height: 18)

            Text(model.formattedTime)
                .monospacedDigit()

            Button(action: model.toggle) {
                Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.plain)

            Button(action: model.stop) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
    }
}
