#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ai-blog-generator-web-app-184382-185529/DatabaseContainer"
VENV_DIR="$WORKSPACE/.venv"
PYTEST_BIN="$VENV_DIR/bin/pytest"
PYTHON="$VENV_DIR/bin/python"
if [ "${TESTING:-0}" != "1" ]; then
  echo "TESTING not enabled; skip tests (set TESTING=1 before deps step to enable)"
  exit 0
fi
if [ ! -x "$PYTEST_BIN" ]; then
  echo "ERROR: pytest not installed in venv; ensure TESTING=1 was set during deps step" >&2
  exit 3
fi
mkdir -p "$WORKSPACE/tests"
cat > "$WORKSPACE/tests/test_app_import.py" <<'PY'
def test_import_installed_package():
    from app import app as flask_app
    assert flask_app is not None
PY
# run pytest, capture output
"$PYTEST_BIN" -q "$WORKSPACE/tests" 2>&1 | tee "$WORKSPACE/pytest_run.log"
exit 0
