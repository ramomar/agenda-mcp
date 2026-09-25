import Core
import MCP
import Foundation

struct ListEvents: AgendaTool {
    struct Arguments: Decodable {
        var start: Date?
        var end: Date?
        var calendars: [String]?
        var query: String?
    }

    struct Output: Encodable {
        let start: Date
        let end: Date
        let count: Int
        let events: [Event]
    }

    let service: AgendaService

    let name = "list_events"
    let description = """
        List calendar events in a date range (at most 4 years). Dates are ISO 8601, such as 2026-09-23 or \
        2026-09-23T09:00:00; times without an offset are in the user's local time zone. Defaults to the next 7 days.
        """
    let inputSchema: Value = [
        "type": "object",
        "properties": [
            "start": ["type": "string", "description": "Range start (ISO 8601). Defaults to now."],
            "end": ["type": "string", "description": "Range end (ISO 8601). Defaults to 7 days after start."],
            "calendars": [
                "type": "array",
                "items": ["type": "string"],
                "description": "Calendar titles or identifiers to filter by.",
            ],
            "query": ["type": "string", "description": "Case-insensitive text to match in the title, location, or notes."],
        ],
    ]

    func run(_ arguments: Arguments) async throws -> Output {
        let range = try DateRange(start: arguments.start, end: arguments.end)
        let events = try await service.events(in: range, inListsNamed: arguments.calendars, matching: arguments.query)
        return Output(start: range.start, end: range.end, count: events.count, events: events)
    }
}
