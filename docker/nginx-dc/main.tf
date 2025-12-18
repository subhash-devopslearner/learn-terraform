provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Pulls the image
resource "docker_image" "nginx" {
  name = "nginx:latest"
  keep_locally = true
}

# Create a container
resource "docker_container" "foo" {
  image = docker_image.nginx.image_id
  name  = "nginx"
  ports {
    external = 8000
    internal = 80
  }
}
