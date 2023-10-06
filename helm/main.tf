# helm/main.tf
resource "null_resource" "helm_init" {
  count = var.enable_helm ? 1 : 0

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "helm init --upgrade"
  }
}
