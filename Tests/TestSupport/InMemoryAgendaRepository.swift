import Core
import Foundation

/// An `AgendaRepository` backed by arrays, for testing Core and the adapters that drive it.
public struct InMemoryAgendaRepository: AgendaRepository {
    public var lists: [AgendaList]
    public var events: [Event]
    public var reminders: [Reminder]

    public init(lists: [AgendaList] = [], events: [Event] = [], reminders: [Reminder] = []) {
        self.lists = lists
        self.events = events
        self.reminders = reminders
    }

    public func lists(of kind: AgendaList.Kind) async throws -> [AgendaList] {
        lists.filter { $0.kind == kind }
    }

    public func events(in range: DateRange, inLists listIDs: [AgendaList.ID]?) async throws -> [Event] {
        let titles = titles(of: listIDs)
        return events.filter { event in
            event.start < range.end && event.end > range.start
                && (titles.map { $0.contains(event.list ?? "") } ?? true)
        }
    }

    public func reminders(withStatus status: ReminderStatus, inLists listIDs: [AgendaList.ID]?) async throws -> [Reminder] {
        let titles = titles(of: listIDs)
        return reminders.filter { reminder in
            status.includes(reminder) && (titles.map { $0.contains(reminder.list ?? "") } ?? true)
        }
    }

    private func titles(of listIDs: [AgendaList.ID]?) -> Set<String>? {
        listIDs.map { ids in Set(lists.filter { ids.contains($0.id) }.map(\.title)) }
    }
}

private extension ReminderStatus {
    func includes(_ reminder: Reminder) -> Bool {
        switch self {
        case .incomplete: !reminder.isCompleted
        case .completed: reminder.isCompleted
        case .all: true
        }
    }
}

extension Date {
    /// A date in the current time zone, for readable fixtures.
    public static func local(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}

extension InMemoryAgendaRepository {
    /// A small agenda around 2026-09-23 with two calendars and one reminder list.
    public static let sample = InMemoryAgendaRepository(
        lists: [
            AgendaList(id: "cal-work", title: "Work", kind: .events),
            AgendaList(id: "cal-home", title: "Home", kind: .events),
            AgendaList(id: "rem-inbox", title: "Inbox", kind: .reminders),
        ],
        events: [
            Event(id: "e2", title: "Dentist", start: .local(2026, 9, 23, 15), end: .local(2026, 9, 23, 16), list: "Home"),
            Event(id: "e1", title: "Standup", start: .local(2026, 9, 23, 9), end: .local(2026, 9, 23, 9, 15), list: "Work", location: "Room Fjord"),
            Event(id: "e3", title: "Planning", start: .local(2026, 10, 5, 10), end: .local(2026, 10, 5, 11), list: "Work"),
        ],
        reminders: [
            Reminder(id: "r1", title: "Buy milk", list: "Inbox"),
            Reminder(id: "r2", title: "Pay rent", list: "Inbox", due: .init(date: .local(2026, 9, 23), includesTime: false)),
            Reminder(id: "r3", title: "Call mom", list: "Inbox", due: .init(date: .local(2026, 9, 23, 18), includesTime: true)),
            Reminder(id: "r4", title: "Book flights", list: "Inbox", due: .init(date: .local(2026, 9, 24), includesTime: false)),
            Reminder(id: "r5", title: "File taxes", isCompleted: true, list: "Inbox", due: .init(date: .local(2026, 9, 23), includesTime: false)),
        ]
    )
}
