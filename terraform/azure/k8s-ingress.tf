resource "kubernetes_ingress" "devsecops_k8s_ingress" {
  metadata {
    name = "devsecops-k8s-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class"                   = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target"    = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"      = "true"
    }
  }

  spec {
    tls {
      hosts = ["k8s.securingthecloud.org"]
      secret_name = "tls-secret"
    }

    rule {
      host = "k8s.securingthecloud.org"

      http {
        path {
          path = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "devsecops-k8s-service"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }
}
