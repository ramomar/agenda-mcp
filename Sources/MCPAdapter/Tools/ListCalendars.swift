import Core
import MCP

struct ListCalendars: AgendaTool {
    struct Arguments: Decodable {
        var type: AgendaList.Kind?
    }

    let service: AgendaService

    let name = "list_calendars"
    let description = "List the user's calendars (which hold events) or reminder lists."
    let inputSchema: Value = [
        "type": "object",
        "properties": [
            "type": [
                "type": "string",
                "enum": ["events", "reminders"],
                "description": "Which kind of lists to return: 'events' for calendars, 'reminders' for reminder lists. Defaults to 'events'.",
            ],
        ],
    ]

    func run(_ arguments: Arguments) async throws -> [AgendaList] {
        try await service.lists(of: arguments.type ?? .events)
    }
}
