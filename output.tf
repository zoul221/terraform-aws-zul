# output "instance_id" {
#   description = "ID of the EC2 instance"
#   value       = aws_instance.use1-svr001-terraform.id
# }

# output "instance_public_ip" {
#   description = "Public IP address of the EC2 instance"
#   value       = aws_instance.use1-svr001-terraform.public_ip
# }

# output "account_id" {
#   value       = data.aws_caller_identity.current.account_id
#   description = "IAM role that Dynatrace should use to get monitoring data"
# }

# output "role_name" {
#   value       = aws_iam_role.monitoring_role.name
#   description = "IAM role that Dynatrace should use to get monitoring data"
# }