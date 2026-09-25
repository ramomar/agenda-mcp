/// The outbound port Core needs to read the user's agenda.
///
/// Implementations only fetch; filtering, sorting, and validation belong to ``AgendaService``.
public protocol AgendaRepository: Sendable {
    func lists(of kind: AgendaList.Kind) async throws -> [AgendaList]

    /// Events overlapping `range`, limited to the given list identifiers (`nil` means all lists).
    func events(in range: DateRange, inLists listIDs: [AgendaList.ID]?) async throws -> [Event]

    /// Reminders with `status`, limited to the given list identifiers (`nil` means all lists).
    func reminders(withStatus status: ReminderStatus, inLists listIDs: [AgendaList.ID]?) async throws -> [Reminder]
}
