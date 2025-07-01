# 1. Create Kinesis Data Stream
resource "aws_kinesis_stream" "stream" {
  name             = "real-time-stream"
  shard_count      = 1
  retention_period = 24
}

# 2. IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "kinesis-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 3. IAM Policy attachment for Kinesis + logs
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "kinesis_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}

# 4. Lambda function that polls REST API and pushes to Kinesis
resource "aws_lambda_function" "poller" {
  function_name    = "poller-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "poller.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30
  filename         = "lambda/poller.zip"
  source_code_hash = filebase64sha256("lambda/poller.zip")
  environment {
    variables = {
      STREAM_NAME    = aws_kinesis_stream.stream.name
      GOOGLE_API_KEY = var.google_api_key
    }
  }
}

# 5. Optional: Trigger this Lambda on schedule (every 1 min)
resource "aws_cloudwatch_event_rule" "every_10_min" {
  name                = "run-every-10-minute"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule      = aws_cloudwatch_event_rule.every_10_min.name
  target_id = "poller"
  arn       = aws_lambda_function.poller.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.poller.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_10_min.arn
}

# 6. IAM Role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "firehose-delivery-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "firehose.amazonaws.com"
      }
    }]
  })
}

# 7. Firehose permissions policy
resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose-policy"
  role = aws_iam_role.firehose_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::use1-test-zul/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:Get*",
          "kinesis:DescribeStream",
          "kinesis:List*"
        ]
        Resource = aws_kinesis_stream.stream.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# 8. Firehose Delivery Stream (Kinesis → S3)
resource "aws_kinesis_firehose_delivery_stream" "to_s3" {
  name        = "firehose-kinesis-to-s3"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_role.arn
    bucket_arn          = "arn:aws:s3:::use1-test-zul"
    prefix              = "firehose-output/!{timestamp:yyyy}/!{timestamp:MM}/!{timestamp:dd}/"
    error_output_prefix = "firehose-errors/!{firehose:error-output-type}/!{timestamp:yyyy}/!{timestamp:MM}/"
    buffering_interval  = 60
    compression_format  = "UNCOMPRESSED"
    file_extension      = ".json"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = "S3Delivery"
    }
  }
}

resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "/aws/kinesisfirehose/firehose-kinesis-to-s3"
  retention_in_days = 14
}


