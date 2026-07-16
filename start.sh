#!/bin/zsh
set -e

SCRIPT_DIR="${0:A:h}"
SPECTRUMVIEWER_DIR="$SCRIPT_DIR/../SpectrumViewer"
BACKEND_PORT=9093
WEBSERVER_PORT=8080
URL="http://localhost:${WEBSERVER_PORT}/analyzerInterface.html?backend=localhost&port=${BACKEND_PORT}"

DRAGON_PID=""
WEBSERVER_PID=""

cleanup() {
    echo "Shutting down..."
    [[ -n $DRAGON_PID ]]    && kill $DRAGON_PID    2>/dev/null; wait $DRAGON_PID    2>/dev/null
    [[ -n $WEBSERVER_PID ]] && kill $WEBSERVER_PID 2>/dev/null; wait $WEBSERVER_PID 2>/dev/null
}
trap cleanup EXIT INT TERM

port_in_use() { nc -z localhost $1 2>/dev/null; }

if port_in_use $BACKEND_PORT; then
    echo "dragon-replay already running on port $BACKEND_PORT — reusing."
else
    echo "Starting dragon-replay..."
    "$SCRIPT_DIR/dragon-replay" &
    DRAGON_PID=$!
    echo "Waiting for backend on port $BACKEND_PORT..."
    until port_in_use $BACKEND_PORT; do sleep 0.5; done
fi

if port_in_use $WEBSERVER_PORT; then
    echo "HTTP server already running on port $WEBSERVER_PORT — reusing."
else
    echo "Starting SpectrumViewer HTTP server on port $WEBSERVER_PORT..."
    python3 -m http.server $WEBSERVER_PORT --directory "$SPECTRUMVIEWER_DIR" &
    WEBSERVER_PID=$!
fi

echo "Opening $URL"
if [[ -d "/Applications/Google Chrome.app" ]]; then
    open -a "Google Chrome" "$URL"
elif [[ -d "/Applications/Firefox.app" ]]; then
    open -a Firefox "$URL"
else
    echo "Warning: Safari may block HTTP. Install Chrome or Firefox for best results."
    open "$URL"
fi

if [[ -n $DRAGON_PID ]]; then
    echo "Press Ctrl+C to stop."
    wait $DRAGON_PID
else
    echo "Both services were already running. Exiting."
fi
