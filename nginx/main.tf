# nginx/main.tf
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx-deployment"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = var.nginx_image
          name  = "nginx"

          ports {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-service"
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

# Optional: Enable HTTPS for NGINX
resource "kubernetes_secret" "tls" {
  count = var.enable_https ? 1 : 0

  metadata {
    name = var.tls_secret_name
  }

  data = {
    "tls.crt" = file("path/to/tls.crt")
    "tls.key" = file("path/to/tls.key")
  }
}

resource "kubernetes_ingress" "nginx" {
  count = var.enable_https ? 1 : 0

  metadata {
    name = "nginx-ingress"
  }

  spec {
    tls {
      secret_name = kubernetes_secret.tls[0].metadata[0].name
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
