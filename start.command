#!/bin/bash

# ─── Fast Pace — Start Script ─────────────────────────────────────────────────
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT=3000

echo ""
echo "  🚀  Fast Pace"
echo "  ─────────────────────────────────"

# ── Kill anything already on port 3000 ───────────────────────────────────────
EXISTING=$(lsof -ti :$PORT 2>/dev/null)
if [ -n "$EXISTING" ]; then
  echo "  ⚡  Freeing port $PORT..."
  echo "$EXISTING" | xargs kill -9 2>/dev/null
  sleep 1
fi

# ── Start Ollama if not running (powers Pacey AI) ────────────────────────────
if ! pgrep -x "ollama" > /dev/null 2>&1; then
  echo "  🤖  Starting Ollama..."
  ollama serve > /tmp/ollama.log 2>&1 &
  sleep 2
else
  echo "  🤖  Ollama already running"
fi

# ── Start Next.js dev server ─────────────────────────────────────────────────
cd "$APP_DIR"
echo "  📦  Starting app server..."
npm run dev > /tmp/fastpace.log 2>&1 &
SERVER_PID=$!

# ── Wait until server is ready ───────────────────────────────────────────────
echo "  ⏳  Waiting for server..."
TRIES=0
until curl -s http://localhost:$PORT > /dev/null 2>&1; do
  sleep 1
  TRIES=$((TRIES + 1))
  if [ $TRIES -ge 30 ]; then
    echo ""
    echo "  ❌  Server failed to start after 30s. Check /tmp/fastpace.log"
    exit 1
  fi
done

# ── Open browser ─────────────────────────────────────────────────────────────
open "http://localhost:$PORT/dashboard"
echo "  ✅  Running at http://localhost:$PORT"
echo "  ─────────────────────────────────"
echo "  Press Ctrl+C to stop the server"
echo ""

# ── Tail the log so Terminal shows live output ───────────────────────────────
tail -f /tmp/fastpace.log &
TAIL_PID=$!

# ── On exit, clean up ────────────────────────────────────────────────────────
trap "kill $SERVER_PID $TAIL_PID 2>/dev/null; echo ''; echo '  Stopped.'; exit 0" INT TERM

wait $SERVER_PID
