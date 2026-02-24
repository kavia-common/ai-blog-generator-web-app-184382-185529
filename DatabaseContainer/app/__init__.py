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
