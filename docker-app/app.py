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

    <h2> How the CI/CD Pipeline Works </h2>
    <p>Every time I push new code to my GitHub repository, a GitHub Actions workflow is triggered. The workflow:</p>
    <ul>
        <li>Runs <b>linting</b> to enforce code quality and style.</li>
        <li>Executes <b>Static Application Security Testing (SAST)</b> using Semgrep.</li>
        <li>Conducts <b>Dynamic Application Security Testing (DAST)</b> using OWASP ZAP.</li>
        <li>Builds a new Docker image and pushes it to Docker Hub.</li>
        <li>Deploys the updated image to the EC2 instance using AWS Systems Manager (SSM).</li>
    </ul>

    <h2> Secure Integration Between GitHub and AWS </h2>
    <p>One of the standout features of this deployment is how my GitHub repository is securely integrated with my AWS environment:</p>
    <ul>
        <li>🔐 <b>OIDC-Based Authentication:</b> Instead of using long-lived access keys, GitHub Actions uses an OpenID Connect (OIDC) provider to authenticate directly with AWS.</li>
        <li>🔑 <b>IAM Roles for GitHub Actions:</b> My GitHub workflow assumes a specific IAM role in AWS, allowing it to deploy resources securely.</li>
        <li>🛡️ <b>No Hardcoded Credentials:</b> Secrets like Docker Hub credentials and Flask secret keys are stored securely in:
            <ul>
                <li><b>GitHub Secrets:</b> For CI/CD pipeline secrets.</li>
                <li><b>AWS SSM Parameter Store:</b> For runtime secrets on the EC2 instance.</li>
            </ul>
        </li>
    </ul>

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
        <li>🔒 <b>Principle of Least Privilege:</b> IAM roles and policies are scoped down to only allow the minimum permissions needed.</li>
        <li>🚨 <b>Automated Security Scanning:</b> The CI/CD pipeline includes:
            <ul>
                <li><b>Linting:</b> Enforcing code style and catching common errors.</li>
                <li><b>Static Analysis (SAST):</b> Using Semgrep to detect security issues in code.</li>
                <li><b>Dynamic Testing (DAST):</b> Using OWASP ZAP to scan the running application for vulnerabilities.</li>
                <li><b>Infrastructure Scanning:</b> Ensuring Terraform configurations follow security best practices.</li>
            </ul>
        </li>
        <li>🛡️ <b>Secure Access Management:</b> SSH access to the server is disabled. Instead, AWS Systems Manager (SSM) is used for secure, auditable access to the instance.</li>
    </ul>

    <h2>📅 Next Steps</h2>
    <p>🔜 Implement HTTPS via AWS ACM & Route 53 for automatic domain resolution. (done!)</p>
    <p>🔜 Set up monitoring and alerting for security events.</p>
    <p>🔜 Expand the blog with more hands-on DevSecOps lessons.</p>

    <hr>
    <p><i>Built with Flask, Terraform, and GitHub Actions. Secured with IAM roles, OIDC authentication, and automated infrastructure updates.</i></p>
    """


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
