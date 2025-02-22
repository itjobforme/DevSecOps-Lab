# models.py

posts = []

def add_post(title, content):
    posts.append({"title": title, "content": content})

def get_posts():
    return posts
