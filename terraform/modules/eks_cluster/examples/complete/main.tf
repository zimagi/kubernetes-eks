provider "aws" {
  region = var.region
}

module "eks" {
  source = "../.."

  region             = var.region
  availability_zones = var.availability_zones
  kubernetes_version = var.kubernetes_version

  node_groups = var.node_groups

  map_additional_iam_users = var.map_additional_iam_users

  context = module.this.context
}