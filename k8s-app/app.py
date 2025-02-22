from flask import Flask
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_host=1)

@app.route("/")
def home():
    return """
    <h1> DevSecOps Lab: Kubernetes Deployment </h1>
    <p>Welcome to the Kubernetes version of my DevSecOps lab! This web app is running in a Kubernetes cluster on Azure Kubernetes Service (AKS).</p>

    <h2> What Makes This Deployment Different? </h2>
    <p>This application is running as a set of pods managed by Kubernetes. Key differences compared to the Docker on EC2 deployment include:</p>
    <ul>
        <li>⚙️ <b>Container Orchestration:</b> Kubernetes handles deploying, scaling, and managing containers automatically.</li>
        <li>📈 <b>Auto-Scaling:</b> Kubernetes can automatically scale the app up or down based on demand.</li>
        <li>🔄 <b>Self-Healing:</b> If a container crashes, Kubernetes will automatically restart it.</li>
        <li>🔀 <b>Load Balancing:</b> Kubernetes uses a service object to distribute traffic across multiple pods.</li>
        <li>🔑 <b>Secrets Management:</b> Using Kubernetes Secrets and ConfigMaps instead of AWS SSM Parameter Store.</li>
        <li>🌐 <b>Ingress and DNS:</b> Configured with an Ingress resource to route external traffic to the app via <code>k8s.securingthecloud.org</code>.</li>
    </ul>

    <h2>📅 Next Steps</h2>
    <p>🔜 Implement advanced security policies like PodSecurityPolicies and NetworkPolicies.</p>
    <p>🔜 Demonstrate canary deployments and rolling updates with Kubernetes.</p>

    <hr>
    <p><i>Built with Flask, deployed on Kubernetes, and secured with best practices for multi-cloud DevSecOps.</i></p>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
