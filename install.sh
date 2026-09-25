#!/usr/bin/env bash
# Builds agenda-mcp and registers it with Claude Code (CLI) and Claude Desktop.
# Usage: ./install.sh [--cli] [--desktop]    (no options: both)
set -euo pipefail

NAME="agenda"
ROOT="$(cd "$(dirname "$0")" && pwd)"
BINARY="$ROOT/.build/release/agenda-mcp"
DESKTOP_CONFIG="${CLAUDE_DESKTOP_CONFIG:-$HOME/Library/Application Support/Claude/claude_desktop_config.json}"

install_cli=false
install_desktop=false
for arg in "$@"; do
    case "$arg" in
        --cli) install_cli=true ;;
        --desktop) install_desktop=true ;;
        -h | --help) sed -n '2,3p' "$0" | cut -c3-; exit 0 ;;
        *) echo "Unknown option: $arg (see --help)" >&2; exit 1 ;;
    esac
done
if ! $install_cli && ! $install_desktop; then
    install_cli=true
    install_desktop=true
fi

echo "==> Building agenda-mcp"
swift build -c release --package-path "$ROOT"

if $install_cli; then
    echo "==> Registering with Claude Code"
    if command -v claude >/dev/null; then
        claude mcp remove "$NAME" -s user >/dev/null 2>&1 || true
        claude mcp add "$NAME" -s user -- "$BINARY"
    else
        echo "    Skipped: 'claude' is not on your PATH." >&2
    fi
fi

if $install_desktop; then
    echo "==> Registering with Claude Desktop"
    mkdir -p "$(dirname "$DESKTOP_CONFIG")"
    if [[ -s "$DESKTOP_CONFIG" ]]; then
        cp "$DESKTOP_CONFIG" "$DESKTOP_CONFIG.bak"
        echo "    Backed up the existing config to $(basename "$DESKTOP_CONFIG").bak"
    fi
    # Merge into mcpServers, keeping any other servers and settings.
    /usr/bin/python3 - "$DESKTOP_CONFIG" "$NAME" "$BINARY" <<'PY'
import json, os, sys

path, name, binary = sys.argv[1:]
config = {}
if os.path.exists(path) and os.path.getsize(path) > 0:
    with open(path) as f:
        config = json.load(f)

config.setdefault("mcpServers", {})[name] = {"command": binary}

with open(path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
PY
    echo "    Added '$NAME' to $DESKTOP_CONFIG"
    echo "    Quit Claude Desktop completely (⌘Q) and reopen it to load the server."
fi
