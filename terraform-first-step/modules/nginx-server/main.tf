resource "docker_container" "nginx_container" {
  image = docker_image.nginx_img.image_id
  name  = var.container_name

  ports {
    internal = 80
    external = var.external_port
  }
}

resource "docker_image" "nginx_img" {
  name         = "nginx:latest"
  keep_locally = false
}