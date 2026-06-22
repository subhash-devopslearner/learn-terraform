terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27.0"
    }
  }
}

# Tell Terraform to use your local Minikube context automatically
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

# 1. Create a dedicated Namespace using Terraform
resource "kubernetes_namespace" "dev_space" {
  metadata {
    name = "terraform-managed-env"
  }
}

# 2. Create a ConfigMap inside that namespace
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "django-config"
    namespace = kubernetes_namespace.dev_space.metadata[0].name
  }

  data = {
    DEBUG        = "True"
    CLUSTER_NAME = "minikube-local"
  }
}