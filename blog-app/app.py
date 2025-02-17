from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <h1>Welcome to My DevSecOps Lab</h1>
    <p>This is a simple web app documenting my journey in DevSecOps.</p>
    <p>It is scanned automatically by OWASP ZAP to test security automation.</p>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
