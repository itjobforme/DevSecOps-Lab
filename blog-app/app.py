import os
import secrets
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from werkzeug.middleware.proxy_fix import ProxyFix

from models import db, User, BlogPost
from admin import admin

app = Flask(__name__, template_folder="templates")
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///blog.db'
secret_key_path = '/app/instance/FLASK_SECRET_KEY'

if os.path.exists(secret_key_path):
    with open(secret_key_path, 'r') as f:
        app.config['SECRET_KEY'] = f.read().strip()
else:
    app.config['SECRET_KEY'] = secrets.token_hex(16)

app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_host=1)

# Initialize extensions
db.init_app(app)

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

admin.init_app(app)

# Create the database if not present
if not os.path.exists('instance/blog.db'):
    with app.app_context():
        db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
