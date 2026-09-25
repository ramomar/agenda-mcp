import Core
import MCP
import os

private let logger = Logger(subsystem: "local.agenda-mcp", category: "Server")

/// Serves an ``AgendaService`` to MCP clients over stdio.
///
/// This is the adapter's only public type; the tools stay internal.
public struct AgendaMCPServer: Sendable {
    private let name: String
    private let version: String
    private let tools: [any AgendaTool]

    public init(service: AgendaService, name: String, version: String) {
        self.name = name
        self.version = version
        self.tools = [
            ListCalendars(service: service),
            ListEvents(service: service),
            ListReminders(service: service),
        ]
    }

    /// Serves requests on stdin and stdout until the client disconnects.
    public func run() async throws {
        let server = await makeServer()
        try await server.start(transport: StdioTransport())
        logger.info("Listening on stdin")

        await server.waitUntilCompleted()
        logger.info("Client disconnected, exiting")
    }

    /// Creates an SDK server with this adapter's tools registered, ready to start on any transport.
    func makeServer() async -> Server {
        let server = Server(name: name, version: version, capabilities: .init(tools: .init()))

        await server.withMethodHandler(ListTools.self) { [tools] _ in
            ListTools.Result(tools: tools.map(\.definition))
        }

        await server.withMethodHandler(CallTool.self) { [tools] params in
            guard let tool = tools.first(where: { $0.name == params.name }) else {
                throw MCPError.invalidParams("Unknown tool: \(params.name)")
            }
            return await tool.call(with: params.arguments)
        }

        return server
    }
}
