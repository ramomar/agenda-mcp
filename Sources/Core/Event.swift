import Foundation

public struct Event: Sendable, Hashable, Codable {
    public let id: String
    public let title: String
    public let start: Date
    public let end: Date
    public let isAllDay: Bool
    public let isRecurring: Bool
    /// The title of the list (calendar) the event belongs to.
    public let list: String?
    public let location: String?
    public let notes: String?
    public let url: URL?
    public let attendees: [String]?

    public init(
        id: String,
        title: String,
        start: Date,
        end: Date,
        isAllDay: Bool = false,
        isRecurring: Bool = false,
        list: String? = nil,
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        attendees: [String]? = nil
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.isRecurring = isRecurring
        self.list = list
        self.location = location
        self.notes = notes
        self.url = url
        self.attendees = attendees
    }
}

extension Event {
    /// Whether the title, location, or notes contain `query` (case- and diacritic-insensitive).
    func matches(_ query: String) -> Bool {
        [title, location, notes]
            .compactMap(\.self)
            .contains { $0.localizedCaseInsensitiveContains(query) }
    }
}
