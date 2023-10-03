resource "aws_sqs_queue" "webhooks_queue" {
  name                       = "${var.project_namespace}-sqs-webhooks-${var.environment}"
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 120
}

data "aws_iam_policy_document" "api_gateway" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = [var.account_id]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.shopify_queue.arn]
  }
}

resource "aws_sqs_queue_policy" "api_gateway_policy" {
  queue_url = aws_sqs_queue.webhooks_queue.id
  policy    = data.aws_iam_policy_document.api_gateway.json
}

resource "aws_sqs_queue" "webhooks_dlq" {
  name = "${var.project_namespace}-sqs-webhooks-${var.environment}"
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.webhooks_queue.arn]
  })
}

resource "aws_sqs_queue_redrive_policy" "webhooks_queue_redrive" {
  queue_url = aws_sqs_queue.webhooks_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.webhooks_dlq.arn
    maxReceiveCount     = 3
  })
}
