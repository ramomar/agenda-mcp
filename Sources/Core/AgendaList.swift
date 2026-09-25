/// A named list that holds either events (a calendar) or reminders (a reminder list).
public struct AgendaList: Sendable, Hashable, Codable, Identifiable {
    public enum Kind: String, Sendable, Hashable, Codable, CaseIterable {
        case events
        case reminders
    }

    public let id: String
    public let title: String
    public let kind: Kind
    public let source: String?
    public let isReadOnly: Bool

    public init(id: String, title: String, kind: Kind, source: String? = nil, isReadOnly: Bool = false) {
        self.id = id
        self.title = title
        self.kind = kind
        self.source = source
        self.isReadOnly = isReadOnly
    }
}

extension AgendaList {
    /// Whether any of `names` is this list's title (case-insensitive) or identifier.
    func matches(anyOf names: [String]) -> Bool {
        names.contains { name in
            name.caseInsensitiveCompare(title) == .orderedSame || name == id
        }
    }
}
