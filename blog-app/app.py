import os
import secrets
import logging
from flask import Flask, render_template, redirect, url_for, request, flash
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from werkzeug.middleware.proxy_fix import ProxyFix
from werkzeug.security import check_password_hash
import pyotp

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

db.init_app(app)

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

admin.init_app(app)

# Set up logging
log_dir = '/app/logs'
log_file = os.path.join(log_dir, 'flask.log')

if not os.path.exists(log_dir):
    os.makedirs(log_dir, exist_ok=True)

file_handler = logging.FileHandler(log_file)
file_handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]')
file_handler.setFormatter(formatter)
app.logger.addHandler(file_handler)

app.logger.setLevel(logging.INFO)
app.logger.info('DevSecOps Blog Startup')

# Route for the main site
@app.route("/")
def home():
    app.logger.info('Accessing the home page')
    posts = BlogPost.query.all()
    return render_template("index.html", posts=posts)

# Add the /login route
@app.route("/login", methods=["GET", "POST"])
def login():
    app.logger.info('Accessing the login page')
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        otp = request.form.get("otp")

        user = User.query.filter_by(username=username).first()

        if user and check_password_hash(user.password_hash, password):
            # Verify OTP if the user has one set up
            if user.otp_secret:
                totp = pyotp.TOTP(user.otp_secret)
                if not totp.verify(otp):
                    flash("Invalid OTP. Please try again.", "danger")
                    return redirect(url_for("login"))

            login_user(user)
            app.logger.info(f'User {username} logged in successfully')
            return redirect(url_for("admin.index"))

        flash("Invalid username or password.", "danger")
        app.logger.warning(f'Failed login attempt for user {username}')

    return render_template("login.html")

# Ensure the database is created
if not os.path.exists('/app/instance/blog.db'):
    with app.app_context():
        db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
