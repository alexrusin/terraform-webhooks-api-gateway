module "lambda-execution-role" {
  source = "../role"

  name               = "${var.project_namespace}-iam-role-lambda-${var.environment}"
  principal_services = ["lambda.amazonaws.com"]
}

module "lambda-execution-role-policy-attachment" {
  source = "../role-policy-attachment"

  role_name   = module.lambda-execution-role.name
  for_each    = toset(["AWSLambdaBasicExecutionRole", "AWSLambdaSQSQueueExecutionRole", "AmazonS3FullAccess"])
  policy_name = each.key
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/index.mjs"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "webhooks_lambda" {
  function_name = "${var.project_namespace}-lambda-webhooks-${var.environment}"
  runtime       = "nodejs18.x"

  filename         = "lambda_function_payload.zip"
  handler          = "index.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256

  role = module.lambda-execution-role.arn

  timeout = 120

  environment {
    variables = {
      BUCKET = var.bucket_name
      REGION = var.region
    }
  }

  lifecycle {
    ignore_changes = [
      timeout,
      reserved_concurrent_executions,
      environment
    ]
  }
}

resource "aws_cloudwatch_log_group" "webhooks_lambda" {
  name = "/aws/lambda/${aws_lambda_function.webhooks_lambda.function_name}"

  retention_in_days = 30
}

resource "aws_lambda_event_source_mapping" "webhooks_sqs_trigger" {
  event_source_arn                   = var.webhooks_queue_arn
  function_name                      = aws_lambda_function.webhooks_lambda.arn
  maximum_batching_window_in_seconds = 20
  function_response_types            = ["ReportBatchItemFailures"]
}
