provider "aws" {
  region = var.region
}

# Get list of availability zones
data "aws_availability_zones" "available" {}
