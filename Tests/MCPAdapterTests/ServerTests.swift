import Core
import Foundation
import MCP
import Testing
import TestSupport
@testable import MCPAdapter

/// End-to-end tests: an SDK client talks to the adapter's server over an in-memory transport.
@Suite struct ServerTests {
    private func connectedClient() async throws -> Client {
        let (clientTransport, serverTransport) = await InMemoryTransport.createConnectedPair()
        let adapter = AgendaMCPServer(
            service: AgendaService(repository: InMemoryAgendaRepository.sample),
            name: "test",
            version: "1"
        )
        try await adapter.makeServer().start(transport: serverTransport)

        let client = Client(name: "test-client", version: "1")
        _ = try await client.connect(transport: clientTransport)
        return client
    }

    /// Calls a tool and returns whether it failed, plus its text output decoded as JSON when possible.
    private func call(_ tool: String, _ arguments: [String: Value] = [:]) async throws -> (isError: Bool, text: String, json: Value?) {
        let (content, isError) = try await connectedClient().callTool(name: tool, arguments: arguments)
        guard case .text(let text, _, _) = content.first else {
            Issue.record("Expected text content")
            return (isError ?? false, "", nil)
        }
        return (isError ?? false, text, try? JSONDecoder().decode(Value.self, from: Data(text.utf8)))
    }

    @Test func advertisesReadOnlyTools() async throws {
        let (tools, _) = try await connectedClient().listTools()

        #expect(tools.map(\.name) == ["list_calendars", "list_events", "list_reminders"])
        #expect(tools.allSatisfy { $0.annotations.readOnlyHint == true })
    }

    @Test func unknownToolIsProtocolError() async throws {
        await #expect(throws: MCPError.self) {
            try await connectedClient().callTool(name: "nope")
        }
    }

    @Test func invalidArgumentsAreToolErrors() async throws {
        let result = try await call("list_events", ["start": "bogus"])
        #expect(result.isError)
        #expect(result.text.contains("start"))
    }

    @Test func rejectsInvertedDateRange() async throws {
        #expect(try await call("list_events", ["start": "2026-09-23", "end": "2026-09-01"]).isError)
    }

    @Test func listCalendarsAcceptsCoreListKinds() async throws {
        let calendars = try await call("list_calendars").json
        let reminderLists = try await call("list_calendars", ["type": "reminders"]).json

        #expect(calendars == [
            ["id": "cal-work", "title": "Work", "kind": "events", "isReadOnly": false],
            ["id": "cal-home", "title": "Home", "kind": "events", "isReadOnly": false],
        ])
        #expect(reminderLists?[0]?["title"] == "Inbox")
        #expect(try await call("list_calendars", ["type": "event"]).isError)
    }

    @Test func listEventsReturnsEventsInRange() async throws {
        let output = try await call("list_events", ["start": "2026-09-23", "end": "2026-09-24", "calendars": ["work"]]).json

        #expect(output?["count"] == 1)
        #expect(output?["events"]?[0]?["title"] == "Standup")
        #expect(output?["events"]?[0]?["list"] == "Work")
    }

    @Test func listRemindersUsesSnakeCaseArgumentsAndLocalTimestamps() async throws {
        let output = try await call("list_reminders", ["due_start": "2026-09-23", "due_end": "2026-09-24"]).json

        #expect(output?["count"] == 2)
        #expect(output?["reminders"]?[0]?["title"] == "Pay rent")
        #expect(output?["reminders"]?[0]?["due"]?["includesTime"] == false)
        #expect(output?["reminders"]?[0]?["due"]?["date"] == .string(Date.local(2026, 9, 23).formatted(.localTimestamp)))
    }
}

private extension Value {
    subscript(key: String) -> Value? {
        objectValue?[key]
    }

    subscript(index: Int) -> Value? {
        arrayValue.flatMap { $0.indices.contains(index) ? $0[index] : nil }
    }
}
