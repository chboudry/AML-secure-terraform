resource "kubernetes_namespace" "nginx_ingress" {
  metadata {
    name = "ingress"
  }
}

# https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.4.2"
  namespace  = kubernetes_namespace.nginx_ingress.metadata.0.name

  set {
    name  = "controller.service.type"
    value = "ClusterIP"
  }
  set {
    name  = "controller.service.internal.enabled"
    value = "true"
  }
  set {
    name  = "controller.service.internal.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
    value = "true"
    type  = "string"
  }
  set {
    name  = "controller.autoscaling.enabled"
    value = "true"
  }
  set {
    name  = "controller.autoscaling.minReplicas"
    value = "2"
  }
  set {
    name  = "controller.autoscaling.maxReplicas"
    value = "10"
  }
}

resource "kubernetes_ingress" "ingress" {
  metadata {
    name = "azureml-fe"
    namespace= "azureml"
  }

  spec {
    ingress_class_name = "ingress-nginx"
    rule {
      http {
        path {
          backend {
            service_name = "azureml-fe"
            service_port = 80
          }
          path = "/aml/"
        }
      }
    }
  }

  depends_on = [
    helm_release.nginx_ingress
  ]
}

resource "local_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = "${path.root}/kubeconfig"
}