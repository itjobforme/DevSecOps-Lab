
app = Flask(__name__)

@app.route("/")
def home():
    return """
    <h1>🚀 DevSecOps Lab: Continuous Security Automation</h1>
    <p>Welcome to my DevSecOps journey! This web app is automatically built, scanned, and deployed using a fully automated pipeline.</p>

    <h2> What We've Achieved So Far</h2>
    <ul>
        <li>✅ <b>Infrastructure as Code:</b> Used Terraform to provision EC2, S3, and networking components.</li>
        <li>✅ <b>Secure Configuration:</b> Enforced IAM policies, enabled IMDSv2, and restricted SSH access.</li>
        <li>✅ <b>CI/CD Pipeline:</b> Configured GitHub Actions to:
            <ul>
                <li>Lint Terraform and Python code</li>
                <li>Run security scans (Semgrep, OWASP ZAP)</li>
                <li>Build and push Docker images to Docker Hub</li>
                <li>Deploy updates automatically on EC2</li>
            </ul>
        </li>
        <li>✅ <b>Automated Security Scans:</b> Integrated OWASP ZAP for DAST and Semgrep for SAST.</li>
        <li>✅ <b>Dynamic Deployment:</b> Any code changes in <code>blog-app/</code> trigger an automatic deployment.</li>
    </ul>

    <h2>📅 Next Steps</h2>
    <p>🔜 Implement HTTPS via AWS ACM & Route 53 for automatic domain resolution</p>
    <p>🔜 Set up monitoring and alerting for security events.</p>
    <p>🔜 Expand the blog with more hands-on DevSecOps lessons.</p>

    <hr>
    <p><i>Built with Flask, Terraform, and GitHub Actions. Scanned automatically for security vulnerabilities.</i></p>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
