terraform { 
  required_providers { 
    kubernetes = { 
      source  = "hashicorp/kubernetes" 
      version = "~> 2.27.0" 
    } 
    helm = { 
      source = "hashicorp/helm" 
    } 
  } 
} 

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "minikube"
  }
}

resource "kubernetes_namespace" "dev_space" {
  metadata {
    name = "terraform-managed-env"
  }
}

resource "helm_release" "django_app" {
  name      = "django-stack"
  
  # Point this directly to the folder where your Chart.yaml file lives!
  # (Update this path to match exactly where your django helm folder is located)
  chart     = "/home/subhash/dev/k8s/djstack/helmcharts/djstack" 

  namespace = kubernetes_namespace.dev_space.metadata[0].name

  # Force Terraform to wait for the storage class to dynamically bind the PVC
  wait          = true
  timeout       = 600  # Give Minikube up to 10 minutes to finish provisioning the storage
  atomic        = true # If it fails, roll back cleanly

  # If you want to override any variables inside your values.yaml, do it here:
  # set {
  #   name  = "replicaCount"
  #   value = "2"
  # }
}