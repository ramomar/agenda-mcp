import Core
import EventKitAdapter
import MCPAdapter

/// Composition root: serves the user's EventKit agenda over MCP.
@main
struct AgendaMCP {
    static func main() async throws {
        let service = AgendaService(repository: EventKitRepository())
        try await AgendaMCPServer(service: service, name: "agenda-mcp", version: "0.4.0").run()
    }
}
