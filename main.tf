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
  name = var.iam_role_name
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

##dynatrace role
data "aws_caller_identity" "current" {}

locals {
  principals_identifiers = var.active_gate_account_id == null || var.active_gate_role_name == null ? [
    "509560245411" # Dynatrace monitoring account ID
    ] : [
    "509560245411", # Dynatrace monitoring account ID
    "arn:aws:iam::${var.active_gate_account_id}:role/${var.active_gate_role_name}"
  ]
}

data "aws_iam_policy_document" "monitoring_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = local.principals_identifiers
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "monitoring_role" {
  name                = var.role_name
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.monitoring_role_policy_document.json
  managed_policy_arns = [aws_iam_policy.monitoring_policy.arn]
}

data "aws_iam_policy_document" "monitoring_policy_document" {
  statement {
    sid = "VisualEditor0"
    actions = [
      "acm-pca:ListCertificateAuthorities",
      "apigateway:GET",
      "apprunner:ListServices",
      "appstream:DescribeFleets",
      "appsync:ListGraphqlApis",
      "athena:ListWorkGroups",
      "autoscaling:DescribeAutoScalingGroups",
      "cloudformation:ListStackResources",
      "cloudfront:ListDistributions",
      "cloudhsm:DescribeClusters",
      "cloudsearch:DescribeDomains",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "codebuild:ListProjects",
      "datasync:ListTasks",
      "dax:DescribeClusters",
      "directconnect:DescribeConnections",
      "dms:DescribeReplicationInstances",
      "dynamodb:ListTables",
      "dynamodb:ListTagsOfResource",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeNatGateways",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeTransitGateways",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpnConnections",
      "ecs:ListClusters",
      "eks:ListClusters",
      "elasticache:DescribeCacheClusters",
      "elasticbeanstalk:DescribeEnvironmentResources",
      "elasticbeanstalk:DescribeEnvironments",
      "elasticfilesystem:DescribeFileSystems",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticmapreduce:ListClusters",
      "elastictranscoder:ListPipelines",
      "es:ListDomainNames",
      "events:ListEventBuses",
      "firehose:ListDeliveryStreams",
      "fsx:DescribeFileSystems",
      "gamelift:ListFleets",
      "glue:GetJobs",
      "inspector:ListAssessmentTemplates",
      "kafka:ListClusters",
      "kinesis:ListStreams",
      "kinesisanalytics:ListApplications",
      "kinesisvideo:ListStreams",
      "lambda:ListFunctions",
      "lambda:ListTags",
      "lex:GetBots",
      "logs:DescribeLogGroups",
      "mediaconnect:ListFlows",
      "mediaconvert:DescribeEndpoints",
      "mediapackage-vod:ListPackagingConfigurations",
      "mediapackage:ListChannels",
      "mediatailor:ListPlaybackConfigurations",
      "opsworks:DescribeStacks",
      "qldb:ListLedgers",
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "rds:DescribeEvents",
      "rds:ListTagsForResource",
      "redshift:DescribeClusters",
      "robomaker:ListSimulationJobs",
      "route53:ListHostedZones",
      "route53resolver:ListResolverEndpoints",
      "s3:ListAllMyBuckets",
      "sagemaker:ListEndpoints",
      "sns:ListTopics",
      "sqs:ListQueues",
      "storagegateway:ListGateways",
      "sts:GetCallerIdentity",
      "swf:ListDomains",
      "tag:GetResources",
      "tag:GetTagKeys",
      "transfer:ListServers",
      "workmail:ListOrganizations",
      "workspaces:DescribeWorkspaces",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "monitoring_policy" {
  name   = var.policy_name
  policy = data.aws_iam_policy_document.monitoring_policy_document.json
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