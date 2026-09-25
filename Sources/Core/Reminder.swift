import Foundation

public struct Reminder: Sendable, Hashable, Codable {
    public enum Priority: String, Sendable, Hashable, Codable, CaseIterable {
        case high, medium, low
    }

    public struct DueDate: Sendable, Hashable, Codable {
        public let date: Date
        /// `false` for reminders due on a day rather than at a specific time.
        public let includesTime: Bool

        public init(date: Date, includesTime: Bool) {
            self.date = date
            self.includesTime = includesTime
        }
    }

    public let id: String
    public let title: String
    public let isCompleted: Bool
    /// The title of the reminder list the reminder belongs to.
    public let list: String?
    public let priority: Priority?
    public let due: DueDate?
    public let completedAt: Date?
    public let notes: String?
    public let url: URL?

    public init(
        id: String,
        title: String,
        isCompleted: Bool = false,
        list: String? = nil,
        priority: Priority? = nil,
        due: DueDate? = nil,
        completedAt: Date? = nil,
        notes: String? = nil,
        url: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.list = list
        self.priority = priority
        self.due = due
        self.completedAt = completedAt
        self.notes = notes
        self.url = url
    }
}

public enum ReminderStatus: String, Sendable, Hashable, Codable, CaseIterable {
    case incomplete
    case completed
    case all
}

extension Reminder {
    /// Whether the reminder is due on or after `start` and before `end`. Reminders without a due date never match a bound.
    func isDue(from start: Date?, before end: Date?) -> Bool {
        guard start != nil || end != nil else { return true }
        guard let date = due?.date else { return false }
        return (start.map { date >= $0 } ?? true) && (end.map { date < $0 } ?? true)
    }

    /// Orders by due date (undated last), then title.
    static func byDueDate(_ lhs: Reminder, _ rhs: Reminder) -> Bool {
        (lhs.due?.date ?? .distantFuture, lhs.title) < (rhs.due?.date ?? .distantFuture, rhs.title)
    }
}
