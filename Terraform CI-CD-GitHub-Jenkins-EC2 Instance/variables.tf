variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr_1" {
  default = "10.0.1.0/24"
  description = "CIDR block for the first public subnet"
}

variable "public_subnet_cidr_2" {
  default = "10.0.2.0/24"
  description = "CIDR block for the second public subnet"
}

variable "ami_id" {
  default     = "ami-0e86e20dae9224db8" # Ubuntu AMI
  description = "AMI ID for EC2 instance"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "key_name" {
  default = "deployer-key"
  description = "Key name for EC2 SSH access"
}

variable "region" {
  default = "us-east-1"
  description = "AWS region"
}
