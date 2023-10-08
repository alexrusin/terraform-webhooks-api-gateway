module "queues" {
  source = "./modules/queues"

  project_namespace = var.project_namespace
  environment       = var.environment
  account_id        = var.account_id
}

module "http-gateway" {
  source = "./modules/http-gateway"

  project_namespace  = var.project_namespace
  environment        = var.environment
  webhooks_queue_url = module.queues.webhooks_queue_url
  webhooks_queue_arn = module.queues.webhooks_queue_arn
}

module "lambda" {
  source = "./modules/lambda"

  project_namespace  = var.project_namespace
  environment        = var.environment
  webhooks_queue_arn = module.queues.webhooks_queue_arn
}
