import os
import secrets

from flask import Flask, redirect, render_template, url_for
from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView
from flask_sqlalchemy import SQLAlchemy
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///blog.db'
app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', secrets.token_hex(16))

app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_host=1)

# Initialize the database
db: SQLAlchemy = SQLAlchemy(app)
admin = Admin(app, name='Blog Admin', template_mode='bootstrap3')

# Database model for blog posts
class BlogPost(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    content = db.Column(db.Text, nullable=False)

# Add the model to Flask-Admin
admin.add_view(ModelView(BlogPost, db.session))

# Route to display all blog posts
@app.route('/')
def home():
    posts = BlogPost.query.all()
    return render_template('index.html', posts=posts)

# Initialize the database if not already present
if not os.path.exists('blog.db'):
    with app.app_context():
        db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
