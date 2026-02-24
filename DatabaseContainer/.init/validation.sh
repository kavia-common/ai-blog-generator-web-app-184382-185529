#!/usr/bin/env bash
set -euo pipefail
# validation: start app in isolated session, check HTTP response, stop cleanly
WORKSPACE="/home/kavia/workspace/code-generation/ai-blog-generator-web-app-184382-185529/DatabaseContainer"
WRAPPER="$WORKSPACE/venv_run.sh"
MANAGE="$WORKSPACE/manage.py"
LOGFILE="$WORKSPACE/validation_app.log"
BODYFILE="$WORKSPACE/validation_body.tmp"
# ensure wrapper and manage exist
if [ ! -x "$WRAPPER" ]; then
  echo "error: wrapper not found or not executable: $WRAPPER" >&2
  exit 3
fi
if [ ! -f "$MANAGE" ]; then
  echo "error: manage.py not found: $MANAGE" >&2
  exit 3
fi
# start app in a new session to isolate process group
setsid "$WRAPPER" "$MANAGE" >"$LOGFILE" 2>&1 &
APP_PID=$!
# small sleep to let process start
sleep 0.2
# robust PGID discovery: prefer ps, fall back to app pid
PGID=""
if command -v ps >/dev/null 2>&1; then
  PGID=$(ps -o pgid= -p "$APP_PID" 2>/dev/null | tr -d ' ' || true)
fi
if [ -z "$PGID" ]; then
  PGID="$APP_PID"
fi
_cleanup() {
  set +e
  # try to terminate process group first
  if [ -n "$PGID" ]; then
    kill -TERM -"$PGID" 2>/dev/null || true
    sleep 1
    kill -KILL -"$PGID" 2>/dev/null || true
  else
    kill "$APP_PID" 2>/dev/null || true
  fi
}
trap _cleanup EXIT INT TERM
# wait up to 30s for HTTP 200 and body contains "\"status\""
HTTP_CODE=000
MAX=30
for i in $(seq 1 $MAX); do
  sleep 1
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "$BODYFILE" http://127.0.0.1:5000/ || echo 000)
  if [ "$HTTP_CODE" = "200" ]; then
    if grep -q '"status"' "$BODYFILE"; then
      break
    fi
  fi
done
if [ "$HTTP_CODE" != "200" ]; then
  echo "validation failed: expected 200 got $HTTP_CODE" >&2
  echo "--- last 200 lines of app log ---" >&2
  tail -n 200 "$LOGFILE" >&2 || true
  echo "--- validation body ---" >&2
  sed -n '1,200p' "$BODYFILE" >&2 || true
  exit 2
fi
# success; cleanup and report
_cleanup
sleep 1
echo "validation_ok: http_status=$HTTP_CODE"
exit 0
