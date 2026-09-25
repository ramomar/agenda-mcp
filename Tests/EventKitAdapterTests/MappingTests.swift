import Core
import Foundation
import Testing
@testable import EventKitAdapter

@Suite struct MappingTests {
    @Test func priorityFollowsEventKitRanges() {
        #expect(Reminder.Priority(eventKitPriority: 0) == nil)
        #expect(Reminder.Priority(eventKitPriority: 1) == .high)
        #expect(Reminder.Priority(eventKitPriority: 5) == .medium)
        #expect(Reminder.Priority(eventKitPriority: 9) == .low)
    }

    @Test func dueDateWithoutHourIsAllDay() throws {
        let day = try #require(Reminder.DueDate(DateComponents(year: 2026, month: 9, day: 23)))
        let moment = try #require(Reminder.DueDate(DateComponents(year: 2026, month: 9, day: 23, hour: 18)))

        #expect(!day.includesTime)
        #expect(moment.includesTime)
    }
}
