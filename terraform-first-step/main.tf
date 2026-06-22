terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

provider "docker" {}

# Instantiate the Development Environment
module "dev_webserver" {
  source         = "./modules/nginx-server"
  container_name = "nginx-env-dev"
  external_port  = 7070
}

# Instantiate the Production Environment
module "prod_webserver" {
  source         = "./modules/nginx-server"
  container_name = "nginx-env-prod"
  external_port  = 9090
}