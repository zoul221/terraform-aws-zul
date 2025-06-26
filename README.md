# terraform-aws-zul
A code repo for building AWS infra using terraform. <br />
Resource that will be provision: <br />
VPC <br />
Subnet <br />
Internet gateway <br />
Route table <br />
Security Group <br />
EC2 <br />
S3


## Prerequisite needed
Terraform Hashicorp is install on your local machine.
https://developer.hashicorp.com/terraform/install <br />

Requires AWS account with user created that have the admin policy attached. <br />
Require the access key and secret key of the user. <br />
Choose the right region of the AWS account that are activated.

Fill in the terraform.tfvars value <br />
aws_region = <br />
aws_accessKey = <br />
aws_secretKey = <br />

## Optional settings to change
The terraform.tfvars can be adjust accordingly based on user prefence

## Steps to execute
Execute the command 
1. Initialize the terraform: <br />
terraform init

2. To see the changes: <br />
terraform plan

3. To apply the changes: <br />
terraform apply

