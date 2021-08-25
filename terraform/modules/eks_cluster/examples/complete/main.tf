provider "aws" {
  region = var.region
}

module "eks" {
  source = "../.."

  region                            = var.region
  availability_zones                = var.availability_zones
  namespace                         = var.namespace
  stage                             = var.stage
  name                              = var.name
  kubernetes_version                = var.kubernetes_version
  cidr_block                        = var.cidr_block
  oidc_provider_enabled             = var.oidc_provider_enabled
  enabled_cluster_log_types         = var.enabled_cluster_log_types
  cluster_log_retention_period      = var.cluster_log_retention_period
  instance_types                    = var.instance_types
  desired_size                      = var.desired_size
  max_size                          = var.max_size
  min_size                          = var.min_size
  disk_size                         = var.disk_size
  kubernetes_labels                 = var.kubernetes_labels
  cluster_encryption_config_enabled = var.cluster_encryption_config_enabled
}