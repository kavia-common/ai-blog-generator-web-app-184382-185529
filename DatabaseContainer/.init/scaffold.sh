#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ai-blog-generator-web-app-184382-185529/DatabaseContainer"
APP_DIR="$WORKSPACE/app"
mkdir -p "$APP_DIR"
# package __init__.py
cat > "$APP_DIR/__init__.py" <<'PY'
from flask import Flask, jsonify
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv
import os, pathlib

load_dotenv()
app = Flask(__name__)
base = pathlib.Path(__file__).resolve().parent.parent
# safe default DATABASE_URL if .env is empty
default_db = f"sqlite:///{base / 'data.db'}"
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL') or default_db
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)

@app.route('/')
def index():
    return jsonify({'status':'ok'})

# create tables in development for convenience
if os.getenv('FLASK_ENV') == 'development':
    with app.app_context():
        db.create_all()
PY
# manage.py launcher
cat > "$WORKSPACE/manage.py" <<'PY'
#!/usr/bin/env python3
import os
from app import app
if __name__ == '__main__':
    port = int(os.getenv('PORT', '5000'))
    app.run(host='0.0.0.0', port=port)
PY
chmod +x "$WORKSPACE/manage.py"
# .env with safe default
cat > "$WORKSPACE/.env" <<'ENV'
FLASK_ENV=development
PORT=5000
DATABASE_URL=
ENV
# pyproject.toml minimal
cat > "$WORKSPACE/pyproject.toml" <<'TOML'
[build-system]
requires = ["setuptools", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "dbcontainer_app"
version = "0.0.0"
TOML
# setup.cfg to ensure find: package discovery for editable install
cat > "$WORKSPACE/setup.cfg" <<'CFG'
[metadata]
name = dbcontainer_app
version = 0.0.0

[options]
packages = find:

CFG
# README with usage notes (TESTING and CREATE_GLOBAL_SYMLINK guidance)
cat > "$WORKSPACE/README.md" <<'MD'
Start the app in the venv with:
  $WORKSPACE/venv_run.sh $WORKSPACE/manage.py
To install package into the venv (editable):
  (inside venv) pip install -e $WORKSPACE
To enable tests during dependency install: export TESTING=1 before running deps step.
To create a global wrapper symlink (opt-in): export CREATE_GLOBAL_SYMLINK=1 before running env step.
MD
exit 0
