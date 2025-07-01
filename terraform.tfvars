# Providers config
aws_region    = "us-east-1"
aws_accessKey = null
aws_secretKey = null
# Network
vpc_cidr_block        = "10.0.0.0/16"
vpc_name              = "use1-vpc001-terraform"
subnet001_cidr_block  = "10.0.1.0/24"
subnet001_name        = "use1-subnet001-terraform"
internet_gateway_name = "use1-igw001-terraform"
route_table_name      = "use1-rt001-terraform"
# EC2
ec2_instance_name = "use1-svr001-terraform"
ec2_instance_type = "t2.micro"
ec2_ip_address    = "10.0.1.1"
# S3
s3_bucket_name = "use1-s3001-terraform"
# IAM
iam_role_name   = "GLO-ROLE001-EC2"
s3_access_level = "full"
# Tags
tag_environment = "Dev"

##dynatrace env
external_id = null
role_name   = "GLO-ROLE001-DYNATRACEMONITORING"
policy_name = "GLO-POL001-DYNATRACEPOL"
# active_gate_account_id=
# active_gate_role_name=
google_api_key = null
