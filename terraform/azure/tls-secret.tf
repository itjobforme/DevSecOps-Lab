resource "kubernetes_secret" "tls_secret" {
  metadata {
    name = "tls-secret"
    namespace = "default"
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = base64decode(var.tls_certificate)
    "tls.key" = base64decode(var.tls_private_key)
  }
}
