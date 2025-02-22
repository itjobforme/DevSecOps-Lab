from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView
from flask_login import current_user
from flask import redirect, url_for, flash

from models import db, User, BlogPost

admin = Admin(name="Blog Admin", template_mode="bootstrap3")

class SecureModelView(ModelView):
    column_exclude_list = ['password_hash', 'otp_secret']
    form_excluded_columns = ['password_hash', 'otp_secret']

    def is_accessible(self):
        if not current_user.is_authenticated:
            print("Access denied: User not authenticated")
            return False
        print("Access granted: User authenticated")
        return True

    def inaccessible_callback(self, name, **kwargs):
        print("Redirecting to login page...")
        flash("Please log in to access this page.", "danger")
        return redirect(url_for("login"))

admin.add_view(SecureModelView(User, db.session))
admin.add_view(SecureModelView(BlogPost, db.session))
