import os
import secrets
from flask import Flask, redirect, render_template, url_for, request, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from werkzeug.middleware.proxy_fix import ProxyFix
from werkzeug.security import generate_password_hash, check_password_hash

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

# Initialize the database
db = SQLAlchemy(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

# User Model
class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)
    otp_secret = db.Column(db.String(16), nullable=True, default=None)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# Blog Post Model
class BlogPost(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    content = db.Column(db.Text, nullable=False)

admin.init_app(app)

if not os.path.exists('instance/blog.db'):
    with app.app_context():
        db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
