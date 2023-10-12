data "aws_iam_policy_document" "webhooks_gateway_to_sqs" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [var.webhooks_queue_arn]
  }
}

resource "aws_iam_policy" "webhooks_gateway_webhooks_sqs" {
  name   = "webhooks-gateway-to-webhooks-sqs"
  policy = data.aws_iam_policy_document.webhooks_gateway_to_sqs.json
}

resource "aws_iam_role" "webhooks_gateway_to_sqs_role" {
  name = "${var.project_namespace}-iam-role-webhooks-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "webhooks_gateway_webhooks_sqs_attachment" {
  role       = aws_iam_role.webhooks_gateway_to_sqs_role.name
  policy_arn = aws_iam_policy.webhooks_gateway_webhooks_sqs.arn
}


resource "aws_apigatewayv2_api" "webhooks_gateway" {
  name          = "${var.project_namespace}-gateway-webhooks-${var.environment}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.webhooks_gateway.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "sqs_integration" {
  api_id              = aws_apigatewayv2_api.webhooks_gateway.id
  description         = "SQS integration"
  credentials_arn     = aws_iam_role.webhooks_gateway_to_sqs_role.arn
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"

  request_parameters = {
    "QueueUrl"    = var.webhooks_queue_url
    "MessageBody" = "$request.body"
    "MessageAttributes" = jsonencode({
      topic = {
        DataType    = "String"
        StringValue = "$${request.header.x-topic}"
      }
      hmac = {
        DataType    = "String"
        StringValue = "$${request.header.x-hmac}"
      }
      webook-id = {
        DataType    = "String"
        StringValue = "$${request.header.x-webhook-id}"
      }
    })
  }
}

resource "aws_apigatewayv2_route" "webhooks_route" {
  api_id    = aws_apigatewayv2_api.webhooks_gateway.id
  route_key = "POST /api/webhooks"

  target = "integrations/${aws_apigatewayv2_integration.sqs_integration.id}"
}
