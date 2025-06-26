# Providers
variable "aws_region" {
    description = "AWS region: us-east-1, us-east-2, ap-southeast-1"
    type = string
    default = "us-east-1"
}
variable "aws_accessKey" {
    description = "AWS Account accessKey"
    type = string
    default = "-"
}
variable "aws_secretKey" {
    description = "AWS Account secretKey"
    type = string
    default = "us-east-1"
}

# Network
variable "vpc_cidr_block" {
  description = "VPC cidr block"
  type        = string
  default     = "10.0.0.0/16"
}
variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "use1-vpc001-terraform"
}

variable "subnet001_cidr_block" {
  description = "VPC subnet cidr block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet001_name" {
  description = "VPC subnet name"
  type        = string
  default     = "use1-subnet001-terraform"
}

variable "internet_gateway_name" {
  description = "Internet gateway name"
  type        = string
  default     = "use1-igw001-terraform"
}

variable "route_table_name" {
  description = "Route table name"
  type        = string
  default     = "use1-rt001-terraform"
}

# Resources
# EC2
variable "ec2_instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "use1-svr001-terraform"
}


variable "ec2_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ec2_ip_address" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# S3
variable "s3_bucket_name" {
  description = "AWS S3 bucket name"
  type        = string
  default     = "use1-s3001-terraform"
}

# IAM role
variable "iam_role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "ec2_ssm_s3_role"
}

variable "s3_access_level" {
  description = "Level of S3 access: full or readonly"
  type        = string
  default     = "full"
}

# Tags
variable "tag_environment" {
  description = "Environment of the resource"
  type        = string
  default     = "Dev"
}