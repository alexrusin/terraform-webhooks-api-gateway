variable "environment" {
  type    = string
  default = "dev"
}

variable "project_namespace" {
  type    = string
  default = "alex"
}

variable "webhooks_queue_url" {
  type        = string
  description = "URL for queue that will receive webhooks from the gateway"
}

variable "webhooks_queue_arn" {
  type        = string
  description = "ARN for queue that will receive webhooks from the gateway"
}
