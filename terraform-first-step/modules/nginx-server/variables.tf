# Define input variables (with default values)
variable "container_name" {
  description = "Name of the Nginx container"
  type        = string
  default     = "my-configurable-nginx"
}

variable "external_port" {
  description = "The external port mapped to the host"
  type        = number
  default     = 8080
}

