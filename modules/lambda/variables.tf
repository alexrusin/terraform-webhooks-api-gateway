variable "environment" {
  type    = string
  default = "dev"
}

variable "project_namespace" {
  type    = string
  default = "alex"
}

variable "webhooks_queue_arn" {
  type        = string
  description = "ARN for queue that will receive webhooks from the gateway"
}

variable "bucket_name" {
  type        = string
  description = "Name of S3 bucket"
}

variable "region" {
  type        = string
  description = "Region for s3 bucket"
}
