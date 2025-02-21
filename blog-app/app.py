import os
import secrets
import pyotp
import qrcode
from io import BytesIO

from flask import Flask, redirect, render_template, url_for, request, flash, send_file
from flask_admin import Admin, AdminIndexView, expose
from flask_admin.contrib.sqla import ModelView
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import DataRequired
from werkzeug.middleware.proxy_fix import ProxyFix
from werkzeug.security import generate_password_hash, check_password_hash

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

# Secure Admin Panel for Users
class SecureUserModelView(ModelView):
    form_columns = ['username', 'password_hash']
    
    form_extra_fields = {
        'password': PasswordField('New Password', default="")
    }

    def on_model_change(self, form, model, is_created):
        if form.password.data:
            model.set_password(form.password.data)

    def is_accessible(self):
        return current_user.is_authenticated

    def inaccessible_callback(self, name, **kwargs):
        return redirect(url_for("login"))

# Secure Admin Panel for Blog Posts
class SecureBlogPostModelView(ModelView):
    form_columns = ['title', 'content']

    def is_accessible(self):
        return current_user.is_authenticated

    def inaccessible_callback(self, name, **kwargs):
        return redirect(url_for("login"))

class SecureAdminIndexView(AdminIndexView):
    @expose("/")
    @login_required
    def index(self):
        return super().index()

admin = Admin(app, name="Blog Admin", template_mode="bootstrap3", index_view=SecureAdminIndexView())
admin.add_view(SecureUserModelView(User, db.session))
admin.add_view(SecureBlogPostModelView(BlogPost, db.session))

# MFA Setup Route
@app.route("/setup-mfa", methods=["GET", "POST"])
@login_required
def setup_mfa():
    if not current_user.otp_secret:
        current_user.otp_secret = pyotp.random_base32()
        db.session.commit()

    otp_uri = f"otpauth://totp/DevSecOpsLab:{current_user.username}?secret={current_user.otp_secret}&issuer=DevSecOpsLab"

    qr = qrcode.make(otp_uri)
    img_io = BytesIO()
    qr.save(img_io, "PNG")
    img_io.seek(0)

    return send_file(img_io, mimetype="image/png")

# Login Form
class LoginForm(FlaskForm):
    username = StringField("Username", validators=[DataRequired()])
    password = PasswordField("Password", validators=[DataRequired()])
    otp = StringField("OTP Code")
    submit = SubmitField("Login")

# Login Route
@app.route("/login", methods=["GET", "POST"])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user and user.check_password(form.password.data):
            if user.otp_secret:
                totp = pyotp.TOTP(user.otp_secret)
                if form.otp.data and totp.verify(form.otp.data):
                    login_user(user)
                    flash("Logged in successfully!", "success")
                    return redirect(url_for("admin.index"))
                else:
                    flash("Invalid OTP code.", "danger")
            else:
                login_user(user)
                flash("First-time login. Please set up MFA.", "info")
                return redirect(url_for("setup_mfa"))
        else:
            flash("Invalid username or password.", "danger")
    return render_template("login.html", form=form)

# Logout Route
@app.route("/logout")
@login_required
def logout():
    logout_user()
    flash("You have been logged out.", "info")
    return redirect(url_for("login"))

# Blog Home Route
@app.route("/")
def home():
    posts = BlogPost.query.all()
    return render_template("index.html", posts=posts)

if not os.path.exists('instance/blog.db'):
    with app.app_context():
        db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
