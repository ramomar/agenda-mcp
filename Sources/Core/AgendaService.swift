import Foundation

/// The read use cases for the user's agenda, independent of where the data comes from or how it's served.
public struct AgendaService: Sendable {
    private let repository: any AgendaRepository

    public init(repository: any AgendaRepository) {
        self.repository = repository
    }

    public func lists(of kind: AgendaList.Kind) async throws -> [AgendaList] {
        try await repository.lists(of: kind)
    }

    /// Events in `range`, sorted by start, optionally limited to lists named `listNames` and matching `query`.
    public func events(
        in range: DateRange,
        inListsNamed listNames: [String]? = nil,
        matching query: String? = nil
    ) async throws -> [Event] {
        let listIDs = try await listIDs(named: listNames, of: .events)
        let query = query.nilIfEmpty

        return try await repository.events(in: range, inLists: listIDs)
            .filter { event in query.map(event.matches) ?? true }
            .sorted { $0.start < $1.start }
    }

    /// Reminders with `status`, sorted by due date, optionally limited by due date and to lists named `listNames`.
    public func reminders(
        withStatus status: ReminderStatus = .incomplete,
        dueFrom dueStart: Date? = nil,
        dueBefore dueEnd: Date? = nil,
        inListsNamed listNames: [String]? = nil
    ) async throws -> [Reminder] {
        let listIDs = try await listIDs(named: listNames, of: .reminders)

        return try await repository.reminders(withStatus: status, inLists: listIDs)
            .filter { $0.isDue(from: dueStart, before: dueEnd) }
            .sorted(by: Reminder.byDueDate)
    }

    // MARK: - Private

    /// Resolves list titles or identifiers to identifiers. Returns `nil`, meaning all lists, when no names are given.
    private func listIDs(named names: [String]?, of kind: AgendaList.Kind) async throws -> [AgendaList.ID]? {
        guard let names = names.nilIfEmpty else { return nil }

        let available = try await repository.lists(of: kind)
        let matches = available.filter { $0.matches(anyOf: names) }

        guard !matches.isEmpty else {
            throw AgendaError.unknownLists(names, available: available.map(\.title))
        }
        return matches.map(\.id)
    }
}
