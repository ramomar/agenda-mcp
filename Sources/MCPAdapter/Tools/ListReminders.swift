import Core
import MCP
import Foundation

struct ListReminders: AgendaTool {
    struct Arguments: Decodable {
        var status: ReminderStatus?
        var dueStart: Date?
        var dueEnd: Date?
        var lists: [String]?
    }

    struct Output: Encodable {
        let count: Int
        let reminders: [Reminder]
    }

    let service: AgendaService

    let name = "list_reminders"
    let description = "List reminders sorted by due date, filtered by status and optionally by due date range and reminder list."
    let inputSchema: Value = [
        "type": "object",
        "properties": [
            "status": [
                "type": "string",
                "enum": ["incomplete", "completed", "all"],
                "description": "Defaults to 'incomplete'.",
            ],
            "due_start": ["type": "string", "description": "Only reminders due on or after this date (ISO 8601)."],
            "due_end": ["type": "string", "description": "Only reminders due before this date (ISO 8601)."],
            "lists": [
                "type": "array",
                "items": ["type": "string"],
                "description": "Reminder list titles or identifiers to filter by.",
            ],
        ],
    ]

    func run(_ arguments: Arguments) async throws -> Output {
        let reminders = try await service.reminders(
            withStatus: arguments.status ?? .incomplete,
            dueFrom: arguments.dueStart,
            dueBefore: arguments.dueEnd,
            inListsNamed: arguments.lists
        )
        return Output(count: reminders.count, reminders: reminders)
    }
}
