provider "helm" {
  kubernetes {
    config_path = "/home/runner/.kube/config"
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.3"

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = var.acm_certificate_arn
            "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "http"
            "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = "https"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
          }
        }
      }
    })
  ]
}

resource "kubernetes_ingress_v1" "k8s_app_ingress" {
  metadata {
    name = "k8s-app-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"  = "true"
      "nginx.ingress.kubernetes.io/use-regex"     = "true"
    }
  }

  spec {
    tls {
      hosts      = ["k8s.securingthecloud.org"]
      secret_name = "k8s-tls-secret"
    }

    rule {
      host = "k8s.securingthecloud.org"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "k8s-app-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
