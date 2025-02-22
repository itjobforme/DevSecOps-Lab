from flask import Flask
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)

# Apply ProxyFix middleware to handle CloudFront headers correctly
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_host=1)


@app.route("/")
def home():
    return """
    <h1> DevSecOps Lab: Continuous Security Automation</h1>
    <p>Welcome to my DevSecOps journey! This web app is automatically built, scanned, and deployed using a fully automated CI/CD pipeline.</p>

    <h2> What This Web App Demonstrates </h2>
    <p>This simple web app is running inside a Docker container on an Amazon EC2 instance. The containerization with Docker means that this app is completely portable — 
    I could take the same Docker image and run it on any platform that supports Docker, such as:</p>
    <ul>
        <li>A different EC2 instance in AWS</li>
        <li>A Kubernetes cluster (e.g., EKS, GKE, or AKS)</li>
        <li>A local development environment</li>
        <li>Other cloud providers (e.g., Azure, Google Cloud, DigitalOcean)</li>
        <li>Edge or IoT devices that support Docker</li>
    </ul>
    <p>Running this app in a container also ensures consistency across environments. Whether I'm testing locally or deploying to the cloud, it works the same way.</p>

    <h2> Why Terraform is Powerful </h2>
    <p>All the infrastructure (EC2 instance, networking, security groups, load balancer, DNS) is provisioned using <b>Terraform</b>. This approach, known as 
    <b>Infrastructure as Code (IaC)</b>, offers several benefits:</p>
    <ul>
        <li><b>Repeatability:</b> I can destroy all resources and redeploy everything within minutes.</li>
        <li><b>Version Control:</b> Changes to the infrastructure are tracked in GitHub alongside application code.</li>
        <li><b>Automated Validation:</b> The CI/CD pipeline includes security checks on the Terraform code, ensuring configurations are secure before deployment.</li>
        <li><b>Disaster Recovery:</b> Since the infrastructure can be rebuilt quickly, recovery from failures is faster and more predictable.</li>
    </ul>

    <h2> How Security is Integrated at Every Step </h2>
    <p>This lab focuses on security throughout the deployment pipeline:</p>
    <ul>
        <li>🔒 <b>No Hardcoded Credentials:</b> All secrets (e.g., Docker login, Flask secret key) are securely stored in:
            <ul>
                <li><b>GitHub Secrets:</b> For CI/CD pipeline secrets</li>
                <li><b>AWS SSM Parameter Store:</b> For runtime secrets on the EC2 instance</li>
            </ul>
        </li>
        <li>🔐 <b>IAM Roles Instead of Access Keys:</b> The EC2 instance uses a role with tightly scoped permissions, avoiding the need for static access keys.</li>
        <li>🚨 <b>Automated Security Scanning:</b> The CI/CD pipeline includes:
            <ul>
                <li><b>Linting:</b> Enforcing code style and catching common errors</li>
                <li><b>Static Application Security Testing (SAST):</b> Using Semgrep to find security issues in code</li>
                <li><b>Dynamic Application Security Testing (DAST):</b> Using OWASP ZAP to scan the running application for vulnerabilities</li>
                <li><b>Terraform Security Scanning:</b> To ensure infrastructure is not being deployed insecurely</li>
            </ul>
        </li>
        <li>🛡️ <b>Secure Access Management:</b> SSH access to the server is disabled. Instead, AWS Systems Manager (SSM) is used for secure, auditable access to the instance.</li>
    </ul>

    <h2>📅 Next Steps</h2>
    <p>🔜 Implement HTTPS via AWS ACM & Route 53 for automatic domain resolution.</p>
    <p>🔜 Set up monitoring and alerting for security events.</p>
    <p>🔜 Expand the blog with more hands-on DevSecOps lessons.</p>

    <hr>
    <p><i>Built with Flask, Terraform, and GitHub Actions. Secured with IAM roles, OIDC authentication, and automated infrastructure updates.</i></p>
    """


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
