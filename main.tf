data "aws_caller_identity" "current" {}

module "label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  attributes = ["cluster"]

  context = module.this.context
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking
  tags = { "kubernetes.io/cluster/${module.label.id}" = "shared" }

  # Unfortunately, most_recent (https://github.com/cloudposse/terraform-aws-eks-workers/blob/34a43c25624a6efb3ba5d2770a601d7cb3c0d391/main.tf#L141)
  # variable does not work as expected, if you are not going to use custom ami you should
  # enforce usage of eks_worker_ami_name_filter variable to set the right kubernetes version for EKS workers,
  # otherwise will be used the first version of Kubernetes supported by AWS (v1.11) for EKS workers but
  # EKS control plane will use the version specified by kubernetes_version variable.
  eks_worker_ami_name_filter = "amazon-eks-node-${var.kubernetes_version}*"

  # required tags to make ALB ingress work https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
  public_subnets_additional_tags = {
    "kubernetes.io/role/elb" : 1
  }
  private_subnets_additional_tags = {
    "kubernetes.io/role/internal-elb" : 1
  }
  efs_policy_name = "${module.label.id}-efs"
  alb_policy_name = "${module.label.id}-alb"
  allow_nfs_ingress_rule = {
    key              = "nfs"
    type             = "ingress"
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    description      = "Allow NFS ingress"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_policy" "efs" {
  name   = local.efs_policy_name
  path   = "/"
  policy = file("${path.module}/policy_documents/aws_efs.json")
}

resource "aws_iam_policy" "alb" {
  name   = local.alb_policy_name
  path   = "/"
  policy = file("${path.module}/policy_documents/aws_alb_ingress_controller.json")
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.21.1"

  cidr_block = "172.16.0.0/16"
  tags       = local.tags

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "0.39.3"

  availability_zones              = var.availability_zones
  vpc_id                          = module.vpc.vpc_id
  igw_id                          = module.vpc.igw_id
  cidr_block                      = module.vpc.vpc_cidr_block
  nat_gateway_enabled             = true
  nat_instance_enabled            = false
  tags                            = local.tags
  public_subnets_additional_tags  = local.public_subnets_additional_tags
  private_subnets_additional_tags = local.private_subnets_additional_tags

  context = module.this.context
}

module "eks_cluster" {
  source  = "cloudposse/eks-cluster/aws"
  version = "0.43.2"

  region                       = var.region
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = concat(module.subnets.private_subnet_ids, module.subnets.public_subnet_ids)
  kubernetes_version           = var.kubernetes_version
  local_exec_interpreter       = var.local_exec_interpreter
  oidc_provider_enabled        = var.oidc_provider_enabled
  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_log_retention_period = var.cluster_log_retention_period

  map_additional_iam_users     = var.map_additional_iam_users

  kube_data_auth_enabled = false
  kube_exec_auth_enabled = true

  cluster_encryption_config_enabled = var.cluster_encryption_config_enabled

  context = module.this.context
}

module "eks_infra_node_group" {
  source  = "cloudposse/eks-node-group/aws"
  version = "0.26.0"

  subnet_ids     = module.subnets.private_subnet_ids
  cluster_name   = module.eks_cluster.eks_cluster_id
  instance_types = ["t3.large"]
  desired_size   = 1
  min_size       = 1
  max_size       = 3
  capacity_type  = "SPOT"
  kubernetes_labels = {
    "node-role.infra" = "true",
    "node-role.compute" = "false",
    "node-role.compute.gpu" = "false"
  }
  create_before_destroy = true
  kubernetes_version    = var.kubernetes_version == null || var.kubernetes_version == "" ? [] : [var.kubernetes_version]

  cluster_autoscaler_enabled = var.cluster_autoscaler_enabled

  # Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
  depends_on = [module.eks_cluster, module.eks_cluster.kubernetes_config_map_id]

  node_role_policy_arns = [
    aws_iam_policy.efs.arn,
    aws_iam_policy.alb.arn
  ]

  context = module.this.context
}

module "eks_node_group" {
  source  = "cloudposse/eks-node-group/aws"
  version = "0.26.0"

  for_each = var.node_groups

  subnet_ids            = module.subnets.private_subnet_ids
  cluster_name          = module.eks_cluster.eks_cluster_id
  instance_types        = each.value.instance_types
  desired_size          = each.value.desired_size
  min_size              = each.value.min_size
  max_size              = each.value.max_size
  kubernetes_labels     = each.value.kubernetes_labels
  capacity_type         = try(each.value.capacity_type, "SPOT")
  create_before_destroy = true
  kubernetes_version    = var.kubernetes_version == null || var.kubernetes_version == "" ? [] : [var.kubernetes_version]

  node_role_policy_arns = [

  ]

  cluster_autoscaler_enabled = var.cluster_autoscaler_enabled

  # Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
  depends_on = [module.eks_cluster, module.eks_cluster.kubernetes_config_map_id]

  node_role_arn = [module.eks_infra_node_group.eks_node_group_role_arn]

  context = module.this.context
}

resource "aws_efs_file_system" "this" {
  depends_on = [
    module.subnets
  ]
  creation_token = module.label.id
  performance_mode = "generalPurpose"

  tags = module.label.tags
}

resource "aws_efs_mount_target" "this" {
  depends_on = [
    module.subnets
  ]
  for_each = {for index, subnet_id in module.subnets.public_subnet_ids : "subnet_${index}" => {"id" : subnet_id}}
  file_system_id = aws_efs_file_system.this.id
  subnet_id      = each.value.id
  security_groups = [module.nfs_sg.id]
}

module "nfs_sg" {
  source  = "cloudposse/security-group/aws"
  version = "0.4.3"

  attributes                 = ["nfs"]
  security_group_description = "Allow NFS access"
  create_before_destroy      = true
  allow_all_egress           = true

  rules = [local.allow_nfs_ingress_rule]

  vpc_id = module.vpc.vpc_id

  context = module.label.context
}



module "helm_release" {
  source = "./modules/helm_release"
  depends_on = [
    module.eks_node_group
  ]
  helm_charts = local.helm_charts
}

module "eks_iam_role" {
  source = "cloudposse/eks-iam-role/aws"
  version     = "0.11.1"
  depends_on = [
    module.eks_cluster
  ]

  aws_account_number          = data.aws_caller_identity.current.account_id
  eks_cluster_oidc_issuer_url = module.eks_cluster.eks_cluster_identity_oidc_issuer

  # Create a role for the service account named `autoscaler` in the Kubernetes namespace `kube-system`
  service_account_name      = local.efs_csi_driver_sa_name
  service_account_namespace = "kube-system"
  aws_iam_policy_document = [file("${path.module}/policy_documents/aws_efs.json")]

  context = module.this.context
}

module "eks_iam_role_alb" {
  source = "cloudposse/eks-iam-role/aws"
  version     = "0.11.1"
  depends_on = [
    module.eks_cluster
  ]

  aws_account_number          = data.aws_caller_identity.current.account_id
  eks_cluster_oidc_issuer_url = module.eks_cluster.eks_cluster_identity_oidc_issuer

  # Create a role for the service account named `autoscaler` in the Kubernetes namespace `kube-system`
  service_account_name      = local.alb_ingress_controller_sa_name
  service_account_namespace = "kube-system"
  aws_iam_policy_document = [file("${path.module}/policy_documents/aws_alb_ingress_controller.json")]

  context = module.this.context
}

# output "efs" {
#   value = module.eks_iam_role
# }