# DevSecOps Training - Hands-On Lab  
🔗 **Live Blog**: https://blog.securingthecloud.org  

This hands-on lab is designed to build practical **DevSecOps** skills by implementing **CI/CD security automation, infrastructure as code, container security, and cloud security monitoring**.  

As part of this project, we have built and deployed a **real-world application**—the live blog at [Securing The Cloud](https://blog.securingthecloud.org). The blog itself is running on **software implemented in this lab**, showcasing DevSecOps best practices in action.  

---

## Part 1: GitHub, CI/CD, and Security Automation  
### ✅ Goals:
- Learn **GitHub Actions** for CI/CD  
- Automate security scans in pipelines  
- Enforce **branch protections & code reviews**  

### Tasks:
1. **Create a GitHub repository** to build a DevSecOps pipeline  
2. **Set up GitHub Actions**:
   - Add a **CI pipeline** using `super-linter`  
   - Integrate **Semgrep** for **SAST scanning**  
3. **Enforce Branch Protection Rules**:
   - Require pull requests before merging  
   - Prevent direct pushes to `main`  
 

---

## Part 2: Infrastructure as Code (Terraform, Ansible)  
### ✅ Goals:
- Use **Terraform** for AWS provisioning  
- Automate configuration with **Ansible**  
- Enforce **least privilege IAM policies**  

### Tasks:
1. **Write Terraform code** to create:
   - VPC, IAM roles, and an EC2 instance  
2. **Secure IAM roles** using **least privilege**  
3. **Use Ansible to harden EC2 instances**:
   - Disable root login  
   - Set up logging & monitoring  
4. **Store Terraform state in S3** with **state locking**  

---

## Part 3: Docker & Kubernetes Security  
### ✅ Goals:
- Secure **Docker containers**  
- Deploy a **Kubernetes (K8s) cluster**  
- Implement **Kubernetes security best practices**  

### Tasks:
1. **Write a Dockerfile** for a simple Flask or Node.js app  
2. **Scan Docker images** using **Trivy** or **Anchore**  
3. **Deploy an app to Kubernetes (Minikube, EKS, or GKE)**  
4. **Harden Kubernetes with security policies**:
   - Implement **network policies**  
   - Enforce **Pod Security Standards (PSS)**  

---

## Part 4: Advanced Security (SAST, DAST, CNAPP, Monitoring)  
### ✅ Goals:
- Automate **SAST, DAST, and SCA scans**  
- Implement **Cloud Security Posture Management (CSPM)**  
- Set up **cloud security monitoring**  

### Tasks:
1. **Integrate DAST scanning** (OWASP ZAP) into CI/CD  
2. **Run Dependency-Check** for **SCA vulnerability detection**  
3. **Enable AWS Security Hub, GuardDuty, or Wiz**  
4. **Set up IAM alerts** for newly created administrator roles  
5. **Install Jenkins** (local or cloud-based) and:
   - Create a **Jenkins pipeline** that runs security checks 

---

## Tracking My Progress  
✅ **Document everything** (committing findings to GitHub)  
**Write about my journey** on [Securing The Cloud](https://blog.securingthecloud.org)
**Engage with security communities** (OWASP, DevSecOps Discords, Reddit)  
