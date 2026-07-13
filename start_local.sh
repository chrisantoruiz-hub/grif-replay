#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VIEWER_DIR="/Users/chris/Work/SpectrumViewer"
URL="http://localhost:9000/analyzerInterface.html?backend=localhost&port=9093"

if [ -x "$SCRIPT_DIR/dragon-replay" ]; then
    echo "Starting dragon-replay server..."
    "$SCRIPT_DIR/dragon-replay" &
    REPLAY_PID=$!
else
    echo "dragon-replay binary not found, assuming already running."
    REPLAY_PID=""
fi

if lsof -i :9000 -sTCP:LISTEN -t &>/dev/null; then
    echo "SpectrumViewer already running on port 9000."
    VIEWER_PID=""
else
    echo "Starting SpectrumViewer web server..."
    node "$VIEWER_DIR/server.js" &
    VIEWER_PID=$!
fi

cleanup() {
    echo "Shutting down..."
    [ -n "$REPLAY_PID" ] && kill "$REPLAY_PID" 2>/dev/null
    [ -n "$VIEWER_PID" ] && kill "$VIEWER_PID" 2>/dev/null
    exit 0
}
trap cleanup INT TERM

sleep 1
echo "Opening browser: $URL"
open "$URL"

echo "Running (Ctrl+C to stop)..."
wait
