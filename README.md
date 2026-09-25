# agenda-mcp

A small, read-only [MCP](https://modelcontextprotocol.io) server (stdio) for Apple Calendar and Reminders,
built on EventKit with a hexagonal (ports and adapters) architecture. The MCP protocol is handled by the
official [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk), pinned to 0.12.x because it is pre-1.0.
Requires macOS 14+ and Swift 6.

## Tools
| Tool | Arguments |
|---|---|
| `list_calendars` | `type`: `events` \| `reminders` |
| `list_events` | `start`, `end` (ISO 8601; default next 7 days), `calendars`, `query` |
| `list_reminders` | `status` (`incomplete` \| `completed` \| `all`), `due_start`, `due_end`, `lists` |

## Build & test
    swift build -c release      # → .build/release/agenda-mcp
    swift test

The first build downloads the SDK and its dependencies (a few minutes, needs network).

## Architecture
Dependencies point inward: `MCPAdapter → Core ← EventKitAdapter`. Only the executable knows all three.

    Sources/
      Core/               Domain (Foundation only): models, AgendaRepository (the outbound port),
                          and AgendaService (the use cases)
      EventKitAdapter/    Driven adapter: EventKitRepository implements AgendaRepository
      MCPAdapter/         Driving adapter: registers typed AgendaTools with the SDK server. Public API: AgendaMCPServer
      AgendaMCP/          Executable (composition root)
    Tests/
      TestSupport/        InMemoryAgendaRepository + fixtures, shared by the test targets
      CoreTests/  EventKitAdapterTests/  MCPAdapterTests/
    Support/Info.plist    Embedded into the binary for the privacy prompts
    install.sh            Builds and registers the server with Claude Code and Claude Desktop

- **Business rules** (the default range, validation, list lookup by name, filtering, sorting) live in `AgendaService`.
- **EventKit specifics** (access, predicates, priority scale) live only in `EventKitAdapter`.
- **Wire format** (tool schemas, snake_case arguments, ISO 8601 parsing, local timestamps) lives only in `MCPAdapter`;
  the SDK handles JSON-RPC, the stdio transport, and protocol version negotiation.

To add a tool, add an `AgendaTool` type in `MCPAdapter/Tools` and register it in `AgendaMCPServer`.
To serve another transport (e.g. HTTP), add a new driving adapter that uses `AgendaService`, plus an executable.

## Quick install
From the project folder:

    ./install.sh                    # build, then register with Claude Code and Claude Desktop
    ./install.sh --cli              # Claude Code only
    ./install.sh --desktop          # Claude Desktop only

The script is safe to re-run. It registers the server as `agenda`:

- **Claude Code:** adds it at user scope, so it's available in every project. Start a new `claude` session to load it.
- **Claude Desktop:** merges it into `~/Library/Application Support/Claude/claude_desktop_config.json`,
  keeping your other servers and backing up the previous file as `claude_desktop_config.json.bak`.
  Quit Claude Desktop completely (⌘Q) and reopen it to load the server.

If the tools don't show up in Claude Desktop, check its MCP logs in `~/Library/Logs/Claude/mcp*.log`.

### Manual setup
Build with `swift build -c release`, then point your client at the absolute path of `.build/release/agenda-mcp`:

    claude mcp add agenda -s user -- /absolute/path/to/.build/release/agenda-mcp

For Claude Desktop, add it under `mcpServers` in `claude_desktop_config.json`:

    { "mcpServers": { "agenda": { "command": "/absolute/path/to/.build/release/agenda-mcp" } } }

## Permissions
The first tool call triggers the macOS Calendars/Reminders prompt. The grant belongs to the app that
launched the server, not to `agenda-mcp` itself. If you denied it, re-enable it in
System Settings › Privacy & Security › Calendars / Reminders.

Launch `claude` from Terminal.app for the prompt to appear. When Claude Desktop (or Claude Code inside it) launches
the server, macOS can refuse access without ever showing the prompt.

Logs go to the unified log: `log stream --predicate 'subsystem == "local.agenda-mcp"'`.
