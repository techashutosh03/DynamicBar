//
//  MeetingFeatures.swift
//  DynamicBar
//

import AppKit
import EventKit
import SwiftUI

struct Meeting: Identifiable {
    let eventID: String?
    let title: String
    let startDate: Date
    let endDate: Date
    let joinURL: URL

    var id: String {
        eventID ?? "\(joinURL.absoluteString)-\(startDate.timeIntervalSince1970)"
    }
}

@MainActor
final class MeetingStore: ObservableObject {
    @Published private(set) var nextMeeting: Meeting?
    @Published private(set) var errorMessage: String?

    private let eventStore = EKEventStore()
    private var calendarAccess: Bool?

    func refresh() async {
        do {
            if calendarAccess == nil {
                calendarAccess = try await requestCalendarAccess()
            }

            guard calendarAccess == true else {
                nextMeeting = nil
                errorMessage = "Calendar access is off."
                return
            }

            let now = Date()
            let start = now.addingTimeInterval(-10 * 60)
            let end = now.addingTimeInterval(2 * 60 * 60)
            let predicate = eventStore.predicateForEvents(
                withStart: start,
                end: end,
                calendars: nil
            )

            let events = eventStore.events(matching: predicate)
                .filter { $0.endDate > now }
                .sorted { $0.startDate < $1.startDate }

            nextMeeting = events.compactMap { event in
                guard let url = meetingURL(in: event) else { return nil }

                return Meeting(
                    eventID: event.eventIdentifier,
                    title: event.title ?? "Meeting",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    joinURL: url
                )
            }.first

            errorMessage = nil
        } catch {
            nextMeeting = nil
            errorMessage = error.localizedDescription
        }
    }

    private func requestCalendarAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Bool, Error>) in

            eventStore.requestFullAccessToEvents { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func meetingURL(in event: EKEvent) -> URL? {
        let sources = [
            event.url?.absoluteString,
            event.location,
            event.notes
        ].compactMap { $0 }

        guard let regex = try? NSRegularExpression(
            pattern: #"https?://[^\s<>"']+"#
        ) else {
            return nil
        }

        let allowedHosts = [
            "zoom.us",
            "meet.google.com",
            "teams.microsoft.com",
            "teams.live.com",
            "teams.office.com"
        ]

        for source in sources {
            let range = NSRange(source.startIndex..., in: source)

            for match in regex.matches(in: source, range: range) {
                guard let matchRange = Range(match.range, in: source) else {
                    continue
                }

                let rawURL = String(source[matchRange])
                    .trimmingCharacters(in: CharacterSet(charactersIn: ".,;:!?)]}"))

                guard let url = URL(string: rawURL),
                      url.scheme?.lowercased() == "https",
                      let host = url.host?.lowercased()
                else {
                    continue
                }

                let isAllowed = allowedHosts.contains {
                    host == $0 || host.hasSuffix("." + $0)
                }

                if isAllowed {
                    return url
                }
            }
        }

        return nil
    }
}

struct MeetingPillView: View {
    @ObservedObject var store: MeetingStore
    let onPreviewCamera: () -> Void

    var body: some View {
        Group {
            if let meeting = store.nextMeeting {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    let seconds = meeting.startDate.timeIntervalSince(timeline.date)

                    if seconds <= 300,
                       seconds >= -600,
                       meeting.endDate > timeline.date {
                        HStack {
                            Button {
                                NSWorkspace.shared.open(meeting.joinURL)
                            } label: {
                                Label(
                                    seconds <= 0
                                        ? "Join now"
                                        : "Meet in \(max(1, Int(ceil(seconds / 60))))m",
                                    systemImage: "video.fill"
                                )
                            }
                            .buttonStyle(.plain)

                            // Camera starts only after the user clicks.
                            Button(action: onPreviewCamera) {
                                Image(systemName: "camera")
                            }
                            .buttonStyle(.plain)
                            .help("Preview your camera")
                        }
                    }
                }
            }
        }
        .task {
            while !Task.isCancelled {
                await store.refresh()
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
    }
}

