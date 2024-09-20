output "ec2_instance_public_ip" {
  value = aws_instance.ec2_instance.public_ip
  description = "Public IP of the EC2 instance"
}

output "vpc_id" {
  value = aws_vpc.main_vpc.id
  description = "VPC ID"
}

output "security_group_id" {
  value = aws_security_group.ec2_pipeline_sg
  description = "Security group ID"
}

output "iam_role_name" {
  value = aws_iam_role.ec2_role.name
  description = "IAM role name"
}
