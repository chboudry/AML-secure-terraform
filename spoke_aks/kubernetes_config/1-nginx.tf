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
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
    type  = "string"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
    value = "true"
    type  = "string"
  }
    set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal-subnet"
    value = "snet-aks"
    type  = "string"
  }
}

resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name = "azureml-fe"
    namespace= "azureml"
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path = "/aml/"
          path_type = "Prefix"
          backend {
            service {
                name = "azureml-fe"
                port {
                    number = 80
                }
            }
          }
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