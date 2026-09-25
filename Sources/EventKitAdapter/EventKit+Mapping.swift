import Core
import EventKit

// Conversions from EventKit objects to Core's value types. Empty values become `nil`.

extension AgendaList {
    init(_ calendar: EKCalendar, kind: Kind) {
        self.init(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            kind: kind,
            source: calendar.source?.title,
            isReadOnly: !calendar.allowsContentModifications
        )
    }
}

extension Event {
    init(_ event: EKEvent) {
        self.init(
            id: event.eventIdentifier ?? event.calendarItemIdentifier,
            title: event.title ?? "",
            start: event.startDate,
            end: event.endDate,
            isAllDay: event.isAllDay,
            isRecurring: event.hasRecurrenceRules,
            list: event.calendar?.title,
            location: event.location.nilIfEmpty,
            notes: event.notes.nilIfEmpty,
            url: event.url,
            attendees: event.attendees.nilIfEmpty?.map { $0.name ?? $0.url.absoluteString }
        )
    }
}

extension Reminder {
    init(_ reminder: EKReminder) {
        self.init(
            id: reminder.calendarItemIdentifier,
            title: reminder.title ?? "",
            isCompleted: reminder.isCompleted,
            list: reminder.calendar?.title,
            priority: Priority(eventKitPriority: reminder.priority),
            due: reminder.dueDateComponents.flatMap { DueDate($0) },
            completedAt: reminder.completionDate,
            notes: reminder.notes.nilIfEmpty,
            url: reminder.url
        )
    }
}

extension Reminder.Priority {
    /// Maps EventKit's 1–9 scale using the ranges documented for `EKReminderPriority`; 0 means no priority.
    init?(eventKitPriority value: Int) {
        switch value {
        case 1...4: self = .high
        case 5: self = .medium
        case 6...9: self = .low
        default: return nil
        }
    }
}

extension Reminder.DueDate {
    /// Due-date components without an hour describe a whole day rather than a moment.
    init?(_ components: DateComponents, calendar: Calendar = .current) {
        guard let date = calendar.date(from: components) else { return nil }
        self.init(date: date, includesTime: components.hour != nil)
    }
}
