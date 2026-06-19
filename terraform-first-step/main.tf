# This tells Terraform to create a local text file on your computer
resource "local_file" "welcome" {
  filename = "${path.module}/welcome.txt"
  content  = "Welcome to the world of Infrastructure as Code!"
}