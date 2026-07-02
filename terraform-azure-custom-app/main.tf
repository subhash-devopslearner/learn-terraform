terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. The Resource Group
resource "azurerm_resource_group" "student_rg" {
  name     = "subhash-student-resources"
  location = "East US"
}

# 2. Azure Container Registry (ACR - Where your custom Docker images will live)
resource "azurerm_container_registry" "acr" {
  name                = "subhashdevopsregistry" # Must be globally unique, alphanumeric only
  resource_group_name = azurerm_resource_group.student_rg.name
  location            = azurerm_resource_group.student_rg.location
  sku                 = "Basic"                 # Cheapest tier, perfect for student free tier
  admin_enabled       = true                    # Enables quick username/password auth for ACI
}

# 3. Deploy Your Custom Django App Natively via ACI
resource "azurerm_container_group" "django_aci" {
  name                = "subhash-django-service"
  location            = azurerm_resource_group.student_rg.location
  resource_group_name = azurerm_resource_group.student_rg.name
  ip_address_type     = "Public"
  os_type             = "Linux"

  # Pass the credentials to unlock your private registry
  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  container {
    name   = "django-app"
    image  = "${azurerm_container_registry.acr.login_server}/django-app:v1" # Dynamically targets your pushed image
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 8000 # Matches your standard Django internal container port
      protocol = "TCP"
    }

    environment_variables = {
      DJANGO_DEBUG         = "True"
      DJANGO_SECRET_KEY    = "django-testing-qtek#6qdie2xmqks60oi#1%6eiefmazw1m&cwn+0-nyk=h%uoa"
      DJANGO_ALLOWED_HOSTS = "*" # Allows Django to accept traffic from Azure's public IP
      
      DB_NAME              = "postgres"
      DB_USER              = "postgres"
      DB_PASSWORD          = "postgres"
      DB_HOST              = "127.0.0.1" # Temporary pointer to clear crash loops
      DB_PORT              = "5432"
    }

  }
}

# Output the login server URL so we know where to push our Docker images
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

# Output the live URL endpoint for your custom Django application
output "django_app_url" {
  description = "The public URL of your custom Django app"
  value       = "http://${azurerm_container_group.django_aci.ip_address}:8000"
}