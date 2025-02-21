import os
import secrets
from flask import Flask, render_template, redirect, url_for, request, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin
from werkzeug.middleware.proxy_fix import ProxyFix
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()
login_manager = LoginManager()

def create_app():
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
    login_manager.init_app(app)
    login_manager.login_view = "login"

    # Import and initialize the admin panel
    from admin import init_admin
    init_admin(app, db)

    with app.app_context():
        if not os.path.exists('instance/blog.db'):
            db.create_all()

    return app

@login_manager.user_loader
def load_user(user_id):
    from models import User
    return User.query.get(int(user_id))

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=80)
