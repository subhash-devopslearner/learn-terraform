output "dev_url" {
  value = module.dev_webserver.container_url
}

output "prod_url" {
  value = module.prod_webserver.container_url
}