# main.tf

provider "aws" {
  region = "us-east-1"
}

# Create an S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-bucket"
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach an IAM policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create a Lambda function
resource "aws_lambda_function" "my_lambda" {
  function_name = "my-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# Create an API Gateway REST API
resource "aws_apigateway_rest_api" "my_api" {
  name        = "my-api"
  description = "My API"
}

# Create an API Gateway resource
resource "aws_apigateway_resource" "my_resource" {
  rest_api_id = aws_apigateway_rest_api.my_api.id
  parent_id   = aws_apigateway_rest_api.my_api.root_resource_id
  path_part   = "my-resource"
}

# Create an API Gateway method
resource "aws_apigateway_method" "my_method" {
  rest_api_id   = aws_apigateway_rest_api.my_api.id
  resource_id   = aws_apigateway_resource.my_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Create an API Gateway integration
resource "aws_apigateway_integration" "my_integration" {
  rest_api_id     = aws_apigateway_rest_api.my_api.id
  resource_id     = aws_apigateway_resource.my_resource.id
  http_method     = aws_apigateway_method.my_method.http_method
  type            = "AWS"
  integration_http_method = "POST"
  uri             = aws_lambda_function.my_lambda.invoke_arn
}

# Create an EventBridge rule
resource "aws_cloudwatch_event_rule" "my_rule" {
  name        = "my-rule"
  description = "My Rule"
  event_pattern = <<EOF
{
  "source": ["aws.apigateway"],
  "detail-type": ["API Gateway Execution Status"],
  "detail": {
    "path": ["/my-resource"],
    "httpMethod": ["POST"]
  }
}
EOF
}

# Create a Step Functions state machine
resource "aws_sfn_state_machine" "my_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.stepfunctions_role.arn

  definition = <<EOF
{
  "Comment": "My State Machine",
  "StartAt": "ProcessImage",
  "States": {
    "ProcessImage": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.my_lambda.arn}",
      "End": true
    }
  }
}
EOF
}

# Create an IAM role for Step Functions
resource "aws_iam_role" "stepfunctions_role" {
  name = "stepfunctions-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach an IAM policy to the Step Functions role
resource "aws_iam_role_policy_attachment" "stepfunctions_policy_attachment" {
  role       = aws_iam_role.stepfunctions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

# Create an Amazon Rekognition collection
resource "aws_rekognition_collection" "my_collection" {
  name = "my-collection"
}

# Create an Amazon Textract role
resource "aws_iam_role" "textract_role" {
  name = "textract-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "textract.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach an IAM policy to the Amazon Textract role
resource "aws_iam_role_policy_attachment" "textract_policy_attachment" {
  role       = aws_iam_role.textract_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonTextractFullAccess"
}
