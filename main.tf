module "queues" {
  source = "./modules/queues"

  project_namespace = var.project_namespace
  environment       = var.environment
  account_id        = var.account_id
}
