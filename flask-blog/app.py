from flask import Flask, render_template, request, redirect, url_for, session, flash
import os
from dotenv import load_dotenv

app = Flask(__name__)
app.config['SECRET_KEY'] = 'supersecretkey'  # Replace with os.getenv('SECRET_KEY') if using .env
load_dotenv()

POSTS = []

@app.route("/")
def home():
    return render_template("index.html", posts=POSTS)

@app.route("/new", methods=["GET", "POST"])
def new_post():
    if 'logged_in' not in session or not session['logged_in']:
        flash("Please log in to create a new post.", "warning")
        return redirect(url_for("login"))
    
    if request.method == "POST":
        title = request.form.get("title")
        content = request.form.get("content")
        if title and content:
            POSTS.append({"title": title, "content": content})
            flash("Post created successfully!", "success")
            return redirect(url_for("home"))
        else:
            flash("Title and content are required.", "danger")
    
    return render_template("new_post.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        password = request.form.get("password")
        if password == os.getenv('ADMIN_PASSWORD'):
            session['logged_in'] = True
            flash("Logged in successfully!", "success")
            return redirect(url_for("home"))
        else:
            flash("Incorrect password.", "danger")
    
    return render_template("login.html")

@app.route("/logout")
def logout():
    session.pop('logged_in', None)
    flash("Logged out successfully.", "success")
    return redirect(url_for("home"))
