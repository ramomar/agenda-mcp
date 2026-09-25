import Foundation
import Testing
import TestSupport
@testable import Core

@Suite struct DateRangeTests {
    @Test func defaultsToOneWeekFromNow() throws {
        let now = Date.local(2026, 9, 23, 12)
        let range = try DateRange(now: now)

        #expect(range.start == now)
        #expect(range.end == .local(2026, 9, 30, 12))
    }

    @Test func rejectsEmptyAndInvertedRanges() {
        let day = Date.local(2026, 9, 23)
        #expect(throws: AgendaError.invalidDateRange(start: day, end: day)) { try DateRange(start: day, end: day) }
        #expect(throws: AgendaError.self) { try DateRange(start: day, end: .local(2026, 9, 1)) }
    }
}

@Suite struct AgendaServiceEventTests {
    let service = AgendaService(repository: InMemoryAgendaRepository.sample)
    let day = try! DateRange(start: .local(2026, 9, 23), end: .local(2026, 9, 24))

    @Test func sortsEventsByStart() async throws {
        let events = try await service.events(in: day)
        #expect(events.map(\.title) == ["Standup", "Dentist"])
    }

    @Test func filtersByQueryAcrossFields() async throws {
        #expect(try await service.events(in: day, matching: "fjord").map(\.id) == ["e1"])
        #expect(try await service.events(in: day, matching: "").count == 2)
    }

    @Test func resolvesListNamesCaseInsensitively() async throws {
        let events = try await service.events(in: day, inListsNamed: ["home"])
        #expect(events.map(\.title) == ["Dentist"])
    }

    @Test func rejectsUnknownListNames() async {
        await #expect(throws: AgendaError.unknownLists(["Gym"], available: ["Work", "Home"])) {
            try await service.events(in: day, inListsNamed: ["Gym"])
        }
    }
}

@Suite struct AgendaServiceReminderTests {
    let service = AgendaService(repository: InMemoryAgendaRepository.sample)

    @Test func defaultsToIncompleteSortedByDueDateWithUndatedLast() async throws {
        let reminders = try await service.reminders()
        #expect(reminders.map(\.title) == ["Pay rent", "Call mom", "Book flights", "Buy milk"])
    }

    @Test func filtersByDueDate() async throws {
        let today = try await service.reminders(dueFrom: .local(2026, 9, 23), dueBefore: .local(2026, 9, 24))
        #expect(today.map(\.title) == ["Pay rent", "Call mom"])
    }

    @Test func filtersByStatus() async throws {
        #expect(try await service.reminders(withStatus: .completed).map(\.title) == ["File taxes"])
        #expect(try await service.reminders(withStatus: .all).count == 5)
    }
}
