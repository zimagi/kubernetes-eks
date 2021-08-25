provider "aws" {
  region = var.region
}

variable "terraform_backend_config_file_path" {
  default = ""
}

module "terraform_state_backend" {
  source  = "cloudposse/tfstate-backend/aws"
  version = "0.33.0"

  namespace  = var.namespace
  stage      = var.stage
  name       = "terraform"
  attributes = ["state"]

  terraform_backend_config_file_path = var.terraform_backend_config_file_path
  terraform_backend_config_file_name = "backend.tf"
  force_destroy                      = true
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  namespace  = var.namespace
  name       = var.name
  stage      = var.stage
  attributes = ["cluster"]
  tags       = var.tags

  context = module.this.context
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking
  tags = merge(var.tags, tomap({ "kubernetes.io/cluster/${module.label.id}" = "shared" }))

  # Unfortunately, most_recent (https://github.com/cloudposse/terraform-aws-eks-workers/blob/34a43c25624a6efb3ba5d2770a601d7cb3c0d391/main.tf#L141)
  # variable does not work as expected, if you are not going to use custom AMI you should
  # enforce usage of eks_worker_ami_name_filter variable to set the right kubernetes version for EKS workers,
  # otherwise the first version of Kubernetes supported by AWS (v1.11) for EKS workers will be used, but
  # EKS control plane will use the version specified by kubernetes_version variable.
  eks_worker_ami_name_filter = "amazon-eks-node-${var.kubernetes_version}*"

  # required tags to make ALB ingress work https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
  public_subnets_additional_tags = {
    "kubernetes.io/role/elb" : 1
  }
  private_subnets_additional_tags = {
    "kubernetes.io/role/internal-elb" : 1
  }
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.21.1"

  cidr_block = var.cidr_block
  tags       = local.tags

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "0.39.3"

  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = true
  nat_instance_enabled = false
  tags                 = local.tags

  public_subnets_additional_tags  = local.public_subnets_additional_tags
  private_subnets_additional_tags = local.private_subnets_additional_tags

  context = module.this.context
}

module "eks_cluster" {
  source  = "cloudposse/eks-cluster/aws"
  version = "0.41.0"

  region                 = var.region
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = concat(module.subnets.private_subnet_ids, module.subnets.public_subnet_ids)
  kubernetes_version     = var.kubernetes_version
  local_exec_interpreter = var.local_exec_interpreter
  oidc_provider_enabled  = var.oidc_provider_enabled
  # enabled_cluster_log_types    = var.enabled_cluster_log_types
  # cluster_log_retention_period = var.cluster_log_retention_period

  cluster_encryption_config_enabled = var.cluster_encryption_config_enabled

  context = module.this.context
}

# Ensure ordering of resource creation to eliminate the race conditions when applying the Kubernetes Auth ConfigMap.
# Do not create Node Group before the EKS cluster is created and the `aws-auth` Kubernetes ConfigMap is applied.
# Otherwise, EKS will create the ConfigMap first and add the managed node role ARNs to it,
# and the kubernetes provider will throw an error that the ConfigMap already exists (because it can't update the map, only create it).
# If we create the ConfigMap first (to add additional roles/users/accounts), EKS will just update it by adding the managed node role ARNs.
data "null_data_source" "wait_for_cluster_and_kubernetes_configmap" {
  inputs = {
    cluster_name             = module.eks_cluster.eks_cluster_id
    kubernetes_config_map_id = module.eks_cluster.kubernetes_config_map_id
  }
}

module "eks_workers" {
  source  = "cloudposse/eks-node-group/aws"
  version = "0.19.0"

  subnet_ids        = module.subnets.private_subnet_ids
  cluster_name      = data.null_data_source.wait_for_cluster_and_kubernetes_configmap.outputs["cluster_name"]
  instance_types    = var.instance_types
  desired_size      = var.desired_size
  min_size          = var.min_size
  max_size          = var.max_size
  kubernetes_labels = var.kubernetes_labels
  disk_size         = var.disk_size
  # eks_worker_ami_name_filter = local.eks_worker_ami_name_filter
  # health_check_type          = var.health_check_type

  # Auto-scaling policies and CloudWatch metric alarms
  # autoscaling_policies_enabled           = var.autoscaling_policies_enabled
  # cpu_utilization_high_threshold_percent = var.cpu_utilization_high_threshold_percent
  # cpu_utilization_low_threshold_percent  = var.cpu_utilization_low_threshold_percent

  context = module.this.context
}
