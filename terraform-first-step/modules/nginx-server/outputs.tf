# Define outputs to display useful data automatically
output "container_url" {
  description = "The URL to access the web server"
  value       = "http://localhost:${var.external_port}"
}