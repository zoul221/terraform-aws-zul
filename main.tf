## Create network ##

## VPC
resource "aws_vpc" "use1-vpc001-terraform" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name        = var.vpc_name
    Environment = var.tag_environment
  }

}

## Subnet
resource "aws_subnet" "use1-subnet001-terraform" {
  vpc_id     = aws_vpc.use1-vpc001-terraform.id
  cidr_block = var.subnet001_cidr_block
  tags = {
    Name        = var.subnet001_name
    Environment = var.tag_environment
  }
}

# ## internet gateway
resource "aws_internet_gateway" "use1-igw001-terraform" {
  vpc_id = aws_vpc.use1-vpc001-terraform.id

  tags = {
    Name        = var.internet_gateway_name
    Environment = var.tag_environment
  }
}

## Route table
resource "aws_route_table" "use1-rt001-terraform" {
  vpc_id = aws_vpc.use1-vpc001-terraform.id

  tags = {
    Name        = var.route_table_name
    Environment = var.tag_environment
  }
}

## aws route
resource "aws_route" "use1-default-route" {
  route_table_id         = aws_route_table.use1-rt001-terraform.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.use1-igw001-terraform.id
}

## Associates route table with subnet
resource "aws_route_table_association" "use1-rtassoc001-terraform" {
  subnet_id      = aws_subnet.use1-subnet001-terraform.id
  route_table_id = aws_route_table.use1-rt001-terraform.id
}

## Security group

resource "aws_security_group" "use1-sg001-terraform" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.use1-vpc001-terraform.id

  tags = {
    Name        = "allow_tls"
    Environment = var.tag_environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.use1-sg001-terraform.id
  cidr_ipv4         = aws_vpc.use1-vpc001-terraform.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.use1-sg001-terraform.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# ## Create IAM role to attached to EC2 instance for SSM
# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_custom_policy" {
  name        = "${var.iam_role_name}_policy"
  description = "Policy for EC2 to access S3 and use Systems Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [

      # Systems Manager core permissions
      {
        Effect = "Allow",
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        Resource = "*"
      },

      # Systems Manager patching and automation
      {
        Effect = "Allow",
        Action = [
          "ssm:DescribeInstanceInformation",
          "ssm:GetCommandInvocation",
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:DescribeDocument",
          "ssm:GetDocument",
          "ssm:ListDocuments"
        ],
        Resource = "*"
      },

      # S3 Access
      {
        Effect   = "Allow",
        Action   = var.s3_access_level == "full" ? ["s3:*"] : ["s3:GetObject", "s3:ListBucket"],
        Resource = ["arn:aws:s3:::*", "arn:aws:s3:::*/*"]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_custom_policy.arn
}

# Instance Profile (needed to attach the IAM role to EC2)
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.iam_role_name}_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# ## create instance of latest amazon linux 2

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ## Create EC2 instance 
resource "aws_instance" "use1-svr001-terraform" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = var.ec2_instance_type

  subnet_id                   = aws_subnet.use1-subnet001-terraform.id
  vpc_security_group_ids      = [aws_security_group.use1-sg001-terraform.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
  #!/bin/bash -ex
  sudo yum update -y
  sudo yum install nginx
  sudo systemctl enable nginx && sudo systemctl start nginx
  echo "<!DOCTYPE html>
  <html>
  <head>
    <title>Welcome Page</title>
  </head>
  <body style="background: linear-gradient(to right, #1e3c72, #2a5298); color: white; font-family: Arial, sans-serif; text-align: center; padding-top: 50px;">
    <h1 style="font-size: 3em; font-weight: bold; text-shadow: 2px 2px #000;">Hi, this server was installed and brought up by Zul using Terraform!</h1>
    <p style="font-size: 1.5em; font-style: italic; color: #ffeb3b;">Installation was a success 🚀</p>
  </body>
  </html>" 
  > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name        = var.ec2_instance_name
    Environment = var.tag_environment
  }

}

resource "aws_s3_bucket" "use1-s3001-terraform" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = var.s3_bucket_name
    Environment = var.tag_environment
  }

}

resource "aws_s3_bucket_policy" "force_ssl_only" {
  bucket = aws_s3_bucket.use1-s3001-terraform.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ForceSSLOnlyAccess",
        Effect = "Deny",
        Principal = {
          AWS = "*"
        },
        Action = "s3:*",
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

## MONTHLY $5 budget
resource "aws_budgets_budget" "zul-monthly-budget" {
  name              = "monthly-budge"
  budget_type       = "COST"
  limit_amount      = "5"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2025-04-01_00:01"

  tags = {
    Environment = var.tag_environment
  }
}