from flask import Flask
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_host=1)

@app.route("/")
def home():
    return '''
    <h1> DevSecOps Lab: Kubernetes Deployment </h1>
    <p>Welcome to the Kubernetes version of my DevSecOps lab! This web app is running in a Kubernetes cluster on an EC2 instance with k3s.</p>

    <h2> What Makes This Deployment Different? </h2>
    <p>This application is running as a set of pods managed by Kubernetes. While both Docker and Kubernetes involve containers, there are some key differences:</p>
    <ul>
        <li>⚙️ <b>Container Orchestration:</b> Docker on EC2 is straightforward—containers are started directly on the host. Kubernetes, on the other hand, abstracts this with pods, deployments, and services, which adds flexibility but also complexity. Unlike Docker Compose, which is typically used to manage multi-container apps locally, Kubernetes offers a robust platform for managing containers at scale across clusters of machines.</li>
        <li>📈 <b>Auto-Scaling:</b> With Docker, you scale manually (e.g., running multiple containers). Kubernetes can automatically scale up or down based on load, but setting this up requires configuring Horizontal Pod Autoscalers and monitoring. This is particularly useful for handling variable traffic patterns without manual intervention.</li>
        <li>🔄 <b>Self-Healing:</b> While Docker requires manual intervention to restart failed containers, Kubernetes offers built-in self-healing by automatically restarting pods. It also performs health checks on containers and can replace or reschedule containers on different nodes if needed.</li>
        <li>🔀 <b>Load Balancing:</b> Kubernetes manages traffic distribution through services, whereas Docker might require external load balancers or manual configuration. Kubernetes services can abstract access to a set of pods and provide automatic load balancing among them.</li>
        <li>🔑 <b>Secrets Management:</b> Docker often uses environment variables or external secrets management tools. Kubernetes uses Secrets and ConfigMaps, which provide more robust and integrated solutions but require additional configuration. Secrets can be mounted as volumes or exposed as environment variables with better security practices.</li>
        <li>🌐 <b>Ingress and DNS:</b> With Kubernetes, setting up Ingress and domain-based routing (e.g., <code>k8s.securingthecloud.org</code>) is powerful but involves configuring Ingress controllers, which is more involved than setting up a simple reverse proxy in Docker. Ingress also provides SSL termination and routing rules, which are great for production environments.</li>
        <li>🚦 <b>Traffic Management:</b> Kubernetes supports advanced traffic routing techniques like canary deployments, blue-green deployments, and traffic splitting. These capabilities are crucial for minimizing risk during deployments and updates.</li>
    </ul>

    <h2>📅 Next Steps</h2>
    <p>🔜 Implement advanced security policies like PodSecurityPolicies and NetworkPolicies to enhance the security posture of the Kubernetes environment.</p>
    <p>🔜 Demonstrate canary deployments and rolling updates with Kubernetes to show how updates can be managed with minimal downtime.</p>
    <p>🔜 Explore using Helm charts for packaging and deploying Kubernetes applications in a modular and reusable manner.</p>

    <hr>
    <p><i>Built with Flask, deployed on Kubernetes, and secured with best practices for multi-cloud DevSecOps.</i></p>
    '''

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
