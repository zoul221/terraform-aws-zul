output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.use1-svr001-terraform.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.use1-svr001-terraform.public_ip
}