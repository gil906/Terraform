resource "kubernetes_secret" "tls" {
  for_each = var.enable_https ? { "tls-secret" = var.tls_secret_name } : {}
  
  metadata {
    name = each.key
  }

  data = {
    "tls.crt" = file("path/to/tls.crt")
    "tls.key" = file("path/to/tls.key")
  }
}

resource "kubernetes_ingress" "nginx" {
  for_each = var.enable_https ? { "nginx-ingress" = var.tls_secret_name } : {}

  metadata {
    name = each.key
  }

  spec {
    tls {
      secret_name = each.value
    }

    rule {
      host = "your-domain.com"
      http {
        path {
          path = "/"
          backend {
            service_name = kubernetes_service.nginx.metadata[0].name
            service_port = kubernetes_service.nginx.spec[0].port[0].port
          }
        }
      }
    }
  }
}
