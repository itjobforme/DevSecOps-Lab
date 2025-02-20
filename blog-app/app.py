import os
import secrets
import pyotp

from flask import Flask, redirect, render_template, url_for, request, flash
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
app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', secrets.token_hex(16))

app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_host=1)

# Initialize the database
db = SQLAlchemy(app)
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

import qrcode
from io import BytesIO
from flask import send_file

@app.route("/setup-mfa")
@login_required
def setup_mfa():
    """Generate a QR code for Google Authenticator."""
    otp_secret = os.getenv("FLASK_OTP_SECRET")
    if not otp_secret:
        flash("MFA is not configured. Contact the administrator.", "danger")
        return redirect(url_for("admin.index"))

    # Generate the OTP URI
    otp_uri = f"otpauth://totp/DevSecOpsLab:{current_user.username}?secret={otp_secret}&issuer=DevSecOpsLab"

    # Generate the QR Code
    qr = qrcode.make(otp_uri)
    img_io = BytesIO()
    qr.save(img_io, "PNG")
    img_io.seek(0)

    return send_file(img_io, mimetype="image/png")


# User Model
class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# 🔹 Move BlogPost model **above** the admin setup
class BlogPost(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    content = db.Column(db.Text, nullable=False)

# Secure Admin Panel
class SecureModelView(ModelView):
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
admin.add_view(SecureModelView(User, db.session))
admin.add_view(SecureModelView(BlogPost, db.session))


class LoginForm(FlaskForm):
    username = StringField("Username", validators=[DataRequired()])
    password = PasswordField("Password", validators=[DataRequired()])
    otp = StringField("OTP Code", validators=[DataRequired()])
    submit = SubmitField("Login")

@app.route("/login", methods=["GET", "POST"])
def login():
    form = LoginForm()
    
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        
        if user and user.check_password(form.password.data):
            # Verify OTP
            otp_secret = os.getenv("FLASK_OTP_SECRET")
            if not otp_secret:
                flash("MFA is not configured. Contact the administrator.", "danger")
                return redirect(url_for("login"))

            totp = pyotp.TOTP(otp_secret)
            if totp.verify(form.otp.data):
                login_user(user)
                flash("Logged in successfully!", "success")
                return redirect(url_for("admin.index"))
            else:
                flash("Invalid OTP code.", "danger")
        else:
            flash("Invalid username or password.", "danger")

    return render_template("login.html", form=form)

@app.route("/logout")
@login_required
def logout():
    logout_user()
    flash("You have been logged out.", "info")
    return redirect(url_for("login"))

# Route to display blog posts
@app.route("/")
def home():
    posts = BlogPost.query.all()
    return render_template("index.html", posts=posts)

# Initialize the database if not already present
if not os.path.exists('blog.db'):
    with app.app_context():
        db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
