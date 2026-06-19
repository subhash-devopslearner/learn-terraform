terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
    }
  }
}

provider "docker" {}

# Pulls the Nginx image
resource "docker_image" "nginx_img" {
  name         = "nginx:latest"
  keep_locally = false
}

# Starts the container and maps port 8080 on your machine to port 80 inside the container
resource "docker_container" "nginx_container" {
  image = docker_image.nginx_img.image_id
  name  = "terraform-nginx-webserver"
  
  ports {
    internal = 80
    external = 9090
  }
}