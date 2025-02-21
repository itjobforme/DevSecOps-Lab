from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView
from flask_login import current_user
from flask import redirect, url_for
from app import db, User, BlogPost

admin = Admin(name="Blog Admin", template_mode="bootstrap3")

class SecureModelView(ModelView):
    column_exclude_list = ['password_hash', 'otp_secret']
    form_excluded_columns = ['password_hash', 'otp_secret']

    def is_accessible(self):
        return current_user.is_authenticated

    def inaccessible_callback(self, name, **kwargs):
        return redirect(url_for("login"))

admin.add_view(SecureModelView(User, db.session))
admin.add_view(SecureModelView(BlogPost, db.session))
