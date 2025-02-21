from flask_admin import Admin, AdminIndexView, expose
from flask_admin.contrib.sqla import ModelView
from flask_login import current_user, login_required
from flask import redirect, url_for

from app import db, User, BlogPost

# Secure Admin Panel for Users
class SecureUserModelView(ModelView):
    form_columns = ['username', 'password']
    form_extra_fields = {
        'password': {'type': 'PasswordField', 'label': 'New Password'}
    }

    def on_model_change(self, form, model, is_created):
        if form.password.data:
            model.set_password(form.password.data)

    def is_accessible(self):
        return current_user.is_authenticated

    def inaccessible_callback(self, name, **kwargs):
        return redirect(url_for('login'))

# Secure Admin Panel for Blog Posts
class SecureBlogPostModelView(ModelView):
    form_columns = ['title', 'content']

    def is_accessible(self):
        return current_user.is_authenticated

    def inaccessible_callback(self, name, **kwargs):
        return redirect(url_for('login'))

class SecureAdminIndexView(AdminIndexView):
    @expose('/')
    @login_required
    def index(self):
        return super().index()

admin = Admin(name='Blog Admin', template_mode='bootstrap3', index_view=SecureAdminIndexView())
admin.add_view(SecureUserModelView(User, db.session))
admin.add_view(SecureBlogPostModelView(BlogPost, db.session))
