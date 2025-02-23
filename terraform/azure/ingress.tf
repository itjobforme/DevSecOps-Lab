apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devsecops-k8s-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
    - hosts:
        - k8s.securingthecloud.org
      secretName: tls-secret
  rules:
    - host: k8s.securingthecloud.org
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: devsecops-k8s-service
                port:
                  number: 443
