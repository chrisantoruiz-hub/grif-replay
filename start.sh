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

kill_stale_port() {
    local port=$1
    local pids
    pids=$(lsof -tiTCP:$port -sTCP:LISTEN 2>/dev/null) || true
    if [[ -n $pids ]]; then
        echo "Killing stale process(es) on port $port: $pids"
        kill $pids 2>/dev/null
        for i in $(seq 1 20); do
            port_in_use $port || break
            sleep 0.2
        done
        if port_in_use $port; then
            echo "Port $port still in use, forcing..."
            kill -9 $pids 2>/dev/null
            for i in $(seq 1 20); do
                port_in_use $port || break
                sleep 0.2
            done
        fi
    fi
}

kill_stale_port $BACKEND_PORT
kill_stale_port $WEBSERVER_PORT

echo "Starting dragon-replay..."
"$SCRIPT_DIR/dragon-replay" &
DRAGON_PID=$!
echo "Waiting for backend on port $BACKEND_PORT..."
until port_in_use $BACKEND_PORT; do sleep 0.5; done

echo "Starting SpectrumViewer HTTP server on port $WEBSERVER_PORT..."
python3 -m http.server $WEBSERVER_PORT --directory "$SPECTRUMVIEWER_DIR" &
WEBSERVER_PID=$!

echo "Opening $URL"
if [[ -d "/Applications/Google Chrome.app" ]]; then
    open -a "Google Chrome" "$URL"
elif [[ -d "/Applications/Firefox.app" ]]; then
    open -a Firefox "$URL"
else
    echo "Warning: Safari may block HTTP. Install Chrome or Firefox for best results."
    open "$URL"
fi

echo "Press Ctrl+C to stop."
wait $DRAGON_PID
