import Core
import EventKit

/// Reads the user's agenda from Calendar and Reminders through EventKit.
///
/// `EKEventStore` isn't `Sendable`, so it's isolated to this actor and only Core's value types leave it.
public actor EventKitRepository: AgendaRepository {
    private let store = EKEventStore()

    public init() {}

    public func lists(of kind: AgendaList.Kind) async throws -> [AgendaList] {
        try await requireAccess(to: kind)
        return store.calendars(for: kind.entityType).map { AgendaList($0, kind: kind) }
    }

    public func events(in range: DateRange, inLists listIDs: [AgendaList.ID]?) async throws -> [Event] {
        try await requireAccess(to: .events)

        let predicate = store.predicateForEvents(
            withStart: range.start,
            end: range.end,
            calendars: calendars(withIDs: listIDs)
        )
        return store.events(matching: predicate).map(Event.init)
    }

    public func reminders(withStatus status: ReminderStatus, inLists listIDs: [AgendaList.ID]?) async throws -> [Reminder] {
        try await requireAccess(to: .reminders)

        let calendars = calendars(withIDs: listIDs)
        let predicate = switch status {
        case .incomplete:
            store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
        case .completed:
            store.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: calendars)
        case .all:
            store.predicateForReminders(in: calendars)
        }

        return await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: (reminders ?? []).map(Reminder.init))
            }
        }
    }

    // MARK: - Private

    private func calendars(withIDs ids: [AgendaList.ID]?) -> [EKCalendar]? {
        ids.map { $0.compactMap(store.calendar(withIdentifier:)) }
    }

    private func requireAccess(to kind: AgendaList.Kind) async throws {
        switch EKEventStore.authorizationStatus(for: kind.entityType) {
        case .fullAccess:
            return
        case .notDetermined:
            guard try await requestFullAccess(to: kind) else { throw EventKitAccessError.denied(kind) }
        default:
            throw EventKitAccessError.denied(kind)
        }
    }

    private func requestFullAccess(to kind: AgendaList.Kind) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let completion: EKEventStoreRequestAccessCompletionHandler = { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
            switch kind {
            case .events: store.requestFullAccessToEvents(completion: completion)
            case .reminders: store.requestFullAccessToReminders(completion: completion)
            }
        }
    }
}

public enum EventKitAccessError: LocalizedError {
    case denied(AgendaList.Kind)

    public var errorDescription: String? {
        switch self {
        case .denied(let kind):
            "Access to \(kind.privacyPaneName) was denied. Grant it in System Settings › Privacy & Security › \(kind.privacyPaneName) for the app that launches this server."
        }
    }
}

extension AgendaList.Kind {
    var entityType: EKEntityType {
        switch self {
        case .events: .event
        case .reminders: .reminder
        }
    }

    /// The matching pane name in System Settings › Privacy & Security.
    var privacyPaneName: String {
        switch self {
        case .events: "Calendars"
        case .reminders: "Reminders"
        }
    }
}
