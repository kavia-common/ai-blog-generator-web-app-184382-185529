#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/ai-blog-generator-web-app-184382-185529/DatabaseContainer"
VENV_DIR="$WORKSPACE/.venv"
PIP="$VENV_DIR/bin/pip"
PYTHON="$VENV_DIR/bin/python"
LOGFILE="$WORKSPACE/venv_pip_install.log"

# Ensure venv exists and create if missing
if [ ! -x "$PYTHON" ]; then
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/python" -m pip install --upgrade pip >/dev/null 2>&1 || true
fi

if [ ! -x "$PIP" ]; then
  echo "ERROR: pip not found in venv: $PIP" >&2
  exit 2
fi

# conservative compatible pins to avoid incompatible majors
PKGS=("Flask>=2.2,<3.0" "Flask-SQLAlchemy>=3.0,<4.0" "SQLAlchemy>=1.4,<3.0" "python-dotenv>=1.0,<2.0")
if [ "${USE_PASSLIB:-0}" = "1" ]; then
  PKGS+=("passlib>=1.7,<2.0")
fi
if [ "${TESTING:-0}" = "1" ]; then
  PKGS+=("pytest>=7.0,<8.0")
fi

# Perform installation and log; fail fast and show tail on error
"$PIP" install --upgrade "${PKGS[@]}" >"$LOGFILE" 2>&1 || { echo "pip install failed; tail of log:" >&2; tail -n 200 "$LOGFILE" >&2; exit 1; }

# Install the workspace package in editable mode
"$PIP" install -e "$WORKSPACE" >>"$LOGFILE" 2>&1 || { echo "pip install -e failed; tail of log:" >&2; tail -n 200 "$LOGFILE" >&2; exit 1; }

# validate installed versions (show first 5 lines of pip show for each)
for pkg in Flask Flask-SQLAlchemy SQLAlchemy python-dotenv; do
  "$PIP" show "$pkg" >/dev/null 2>&1 || echo "WARN: $pkg not found in venv" >&2
  echo "---- $pkg ----"
  "$PIP" show "$pkg" | sed -n '1,5p' || true
done

# quick import validation
"$PYTHON" - <<'PY'
import sys
try:
    import flask
    import flask_sqlalchemy
    import dotenv
except Exception as e:
    raise SystemExit('dependency import failed: '+repr(e))
print('deps_ok')
PY

exit 0
