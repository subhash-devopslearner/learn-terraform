terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # 1. Force Terraform to use standard local URL paths for S3 buckets!
  s3_use_path_style           = true

  endpoints {
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
    iam = "http://localhost:4566"
  }
}

# 1. Create a Virtual Cloud Network
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "my-local-vpc"
  }
}

# 2. Create an S3 Storage Bucket
resource "aws_s3_bucket" "storage_bucket" {
  bucket = "subhash-devops-test-bucket"
}

# 3. Create a Subnet inside your VPC network (needed to place an EC2 instance)
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "my-local-subnet"
  }
}

# 4. Launch your Virtual Compute Server (EC2)
resource "aws_instance" "web_server" {
  # In LocalStack, any dummy AMI string works for mock testing
  ami           = "ami-0c55b159cbfafe1f0" 
  instance_type = "t2.micro" # Strictly within the free-tier size framework
  subnet_id     = aws_subnet.public_subnet.id

  # Attach the IAM credentials directly to the virtual machine!
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "django-cloud-host"
  }
}

# 5. Create a trust policy allowing EC2 instances to assume this IAM Role
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 6. Attach a built-in AWS Policy for Amazon S3 Full Access to our new Role
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# 7. Create an Instance Profile (this is the bridge that passes the role to the hardware)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-s3-instance-profile"
  role = aws_iam_role.ec2_s3_access_role.name
}