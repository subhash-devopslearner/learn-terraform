terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# The standard Microsoft Azure Provider configuration
provider "azurerm" {
  features {}
}

# 1. Create a Resource Group (The container for all your cloud components)
resource "azurerm_resource_group" "student_rg" {
  name     = "subhash-student-resources"
  location = "East US" # East US is highly compatible with student free credits
}

# 2. Virtual Network (VNet - The private cloud network)
resource "azurerm_virtual_network" "vnet" {
  name                = "subhash-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.student_rg.location
  resource_group_name = azurerm_resource_group.student_rg.name
}

# 3. Subnet (An isolated segment inside the VNet)
resource "azurerm_subnet" "subnet" {
  name                 = "internal-subnet"
  resource_group_name  = azurerm_resource_group.student_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 4. Public IP (So we can connect to our VM from the internet later)
resource "azurerm_public_ip" "public_ip" {
  name                = "vm-public-ip"
  resource_group_name = azurerm_resource_group.student_rg.name
  location            = azurerm_resource_group.student_rg.location
  allocation_method   = "Static"
}

# 5. Network Interface Card (NIC - The virtual network card for our VM)
resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.student_rg.location
  resource_group_name = azurerm_resource_group.student_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# 6. Linux Virtual Machine (Our compute server)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "subhash-linux-vm"
  resource_group_name = azurerm_resource_group.student_rg.name
  location            = azurerm_resource_group.student_rg.location
  size                = "Standard_B1s" # Extremely low-cost size, perfect for student tiers
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # Authentication via password for quick learning configuration
  admin_password                  = "ComplexPassword123!" # Change this to your own password
  disable_password_authentication = false

  # 🚀 AUTOMATED BOOTSTRAP SCRIPT ADDED HERE!
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    # Add the admin user to the docker group so you don't need 'sudo' for docker commands later
    sudo usermod -aG docker azureuser

    # Run a simple Nginx container on Port 80 to verify our cloud-init worked!
    sudo docker run -d -p 80:80 --name local-test-web nginx
  EOF
  )

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts" # Matches your local Ubuntu environment layout
    sku       = "server"
    version   = "latest"
  }
}

# 7. Create the Cloud Firewall (Network Security Group)
resource "azurerm_network_security_group" "nsg" {
  name                = "vm-security-group"
  location            = azurerm_resource_group.student_rg.location
  resource_group_name = azurerm_resource_group.student_rg.name

  # Rule A: Open Port 22 for SSH access
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Rule B: Open Port 80 for Web Traffic
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 8. Attach the Firewall directly to your VM's Network Interface Card (NIC)
resource "azurerm_network_interface_security_group_association" "nic_nsg_link" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

output "vm_public_ip" {
  description = "The public IP address of your new live Azure VM"
  value       = azurerm_public_ip.public_ip.ip_address
}
