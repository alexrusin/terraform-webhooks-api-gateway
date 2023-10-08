output "webhooks_queue_url" {
  value = aws_sqs_queue.webhooks_queue.url
}

output "webhooks_queue_arn" {
  value = aws_sqs_queue.webhooks_queue.arn
}
