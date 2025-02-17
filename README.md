# DevSecOps Training - Hands-On Lab

## 📌 Part 1: GitHub, CI/CD, and Security Automation
### ✅ Goals:
- **GitHub Actions** & **Jenkins** for CI/CD
- Automate security scans in pipelines
- Set up **branch protections & code reviews**

### 🔨 Tasks:
1. **Create GitHub Repository** for testing DevSecOps pipeline
2. **Set up GitHub Actions**:
   - Add a CI pipeline with `super-linter`
   - Integrate **Semgrep** for SAST scanning
3. **Configure Branch Protection Rules**:
   - Require pull requests before merging
   - Prevent direct pushes to `main`
4. **Install Jenkins** (local or cloud-based)
   - Create a Jenkins pipeline that runs security checks

---

## 📌 Part 2: Infrastructure as Code (Terraform, Ansible)
### ✅ Goals:
- **Terraform** for AWS provisioning
- Use **Ansible** for server configuration
- Implement **least privilege IAM policies**

### 🔨 Tasks:
1. **Write Terraform script** to create:
   - VPC, IAM role, and EC2 instance
2. **Secure IAM roles** with least privilege policies
3. **Use Ansible to configure EC2 securely**:
   - Disable root login
   - Set up logging & monitoring
4. **Store Terraform state in S3** with state locking

---

## 📌 Part 3: Docker & Kubernetes Security
### ✅ Goals:
- Build and secure **Docker containers**
- Deploy a **Kubernetes (K8s) cluster**
- Implement **Kubernetes security best practices**

### 🔨 Tasks:
1. **Write a Dockerfile** for a simple Flask or Node.js app
2. **Scan Docker images** using **Trivy** or **Anchore**
3. **Deploy an app to Kubernetes (Minikube/EKS/GKE)**
4. **Implement Kubernetes network policies**
5. **Apply Pod Security Policies (PSP)**

---

## 📌 Part 4: Advanced Security (SAST, DAST, CNAPP, Monitoring)
### ✅ Goals:
- Automate **SAST, DAST, and SCA scans**
- Implement **Cloud Security Posture Management (CSPM)**
- Set up **cloud security monitoring**

### 🔨 Tasks:
1. **Add DAST scanning (OWASP ZAP) to CI/CD pipeline**
2. **Run Dependency-Check for SCA vulnerability detection**
3. **Enable AWS Security Hub, GuardDuty, or Wiz**
4. **Create IAM alerts for new administrator roles**
5. **Set up CloudWatch/SIEM alerts for security events**

---

## 🚀 Tracking Progress
- **Document everything** (commit findings to GitHub)
- **Write LinkedIn posts** about what you’re building
- **Engage in security communities** (OWASP, DevSecOps Discords)


