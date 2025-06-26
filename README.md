# terraform-aws-zul
A code repo for building AWS infra using terraform

## Prerequisite needed
Terraform Hashicorp is install on your local machine.
https://developer.hashicorp.com/terraform/install

Requires AWS account with user created that have the admin policy attached. Require the access key and secret key of the user.
Choose the right region of the AWS account that are activated.

Fill in the terraform.tfvars value
aws_region =
aws_accessKey =
aws_secretKey =

## Optional settings to change
The terraform.tfvars can be adjust accordingly based on user prefence

## Steps to execute
Execute the command 
1. Initialize the terraform:
terraform init

2. To see the changes:
terraform plan

3. To apply the changes:
terraform apply

