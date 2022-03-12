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

  # map_additional_aws_accounts  = var.map_additional_aws_accounts
  # map_additional_iam_roles     = var.map_additional_iam_roles
  # map_additional_iam_users     = var.map_additional_iam_users

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
  kubernetes_labels = {
    zimagi = "infra"
  }
  create_before_destroy = true
  kubernetes_version    = var.kubernetes_version == null || var.kubernetes_version == "" ? [] : [var.kubernetes_version]

  cluster_autoscaler_enabled = var.cluster_autoscaler_enabled

  # Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
  module_depends_on = module.eks_cluster.kubernetes_config_map_id

  node_role_arn = []

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
  create_before_destroy = true
  kubernetes_version    = var.kubernetes_version == null || var.kubernetes_version == "" ? [] : [var.kubernetes_version]

  cluster_autoscaler_enabled = var.cluster_autoscaler_enabled

  # Prevent the node groups from being created before the Kubernetes aws-auth ConfigMap
  module_depends_on = module.eks_cluster.kubernetes_config_map_id

  node_role_arn = [module.eks_infra_node_group.eks_node_group_role_arn]

  context = module.this.context
}

module "autoscaler_role" {
  count = var.cluster_autoscaler_enabled ? 1 : 0

  source  = "cloudposse/eks-iam-role/aws"
  version = "0.10.1"

  aws_account_number          = data.aws_caller_identity.current.account_id
  eks_cluster_oidc_issuer_url = module.eks_cluster.eks_cluster_identity_oidc_issuer

  service_account_name      = "cluster-autoscaler"
  service_account_namespace = "kube-system"
  aws_iam_policy_document   = join("", data.aws_iam_policy_document.autoscaler.*.json)

  context = module.this.context
}

# module "aws_load_balancer_controller_role" {
#   source = "cloudposse/eks-iam-role/aws"
#   version     = "0.10.1"

#   aws_account_number          = var.aws_account_number
#   eks_cluster_oidc_issuer_url = module.eks_cluster.eks_cluster_identity_oidc_issuer

#   service_account_name      = var.service_account_name
#   service_account_namespace = "aws-load-balancer-controller"
#   aws_iam_policy_document     = file("policy_documents/aws_load_balncer_policy.json")

#   context = module.this.context
# }

data "aws_iam_policy_document" "autoscaler" {
  count = var.cluster_autoscaler_enabled ? 1 : 0

  statement {
    sid = "AllowToScaleEKSNodeGroupAutoScalingGroup"

    actions = [
      "ec2:DescribeLaunchTemplateVersions",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeAutoScalingGroups"
    ]

    effect    = "Allow"
    resources = ["*"]
  }
}

locals {
  autoscaler_serviceaccount_name = "cluster-autoscaler"
}


data "template_file" "values" {
  template = file("${path.module}/templates/values.yaml.tpl")
  vars = {
    autoDiscovery_clusterName                = module.eks_cluster.eks_cluster_id
    awsRegion                                = var.region
    image_tag                                = "v${var.kubernetes_version}.0"
    rbac_serviceAccount_annotations_eks_role = module.autoscaler_role[0].service_account_role_arn
    rbac_serviceAccount_name                 = local.autoscaler_serviceaccount_name
  }

  depends_on = [module.eks_cluster]
}

locals {
  helm_charts = {
    argocd = {
      name = "argocd"
      chart = "argo-cd"
      repository = "https://argoproj.github.io/argo-helm"
      namespace = "argocd"
      create_namespace = true
      sets = {
        ui_service = {
          name = "server.service.type"
          value = "LoadBalancer"
        }
      }
    }
    # metric-server = {
    #   name       = "metrics-server"
    #   chart      = "metrics-server"
    #   repository = "https://kubernetes-sigs.github.io/metrics-server/"
    #   namespace  = "kube-system"
    # }
    # cluster-autoscaler = {
    #   name       = "aws-cluster-autoscaler"
    #   chart      = "cluster-autoscaler"
    #   repository = "https://kubernetes.github.io/autoscaler"
    #   namespace  = "kube-system"
    #   values     = [data.template_file.values.rendered]
    # }
    # zimagi = {
    #   name = "zimagi"
    #   chart = "zimagi"
    #   repository = "https://charts.zimagi.com"
    #   namespace = "zimagi"
    #   create_namespace = true
    # }
    # csi-secrets-store-provider-aws = {
    #   name = "csi-secrets-store-provider-aws"
    #   chart = "csi-secrets-store-provider-aws"
    #   repository = "https://aws.github.io/eks-charts"
    #   namespace = "csi-secrets-store-provider-aws"
    #   create_namespace = true
    # }
    # aws-load-balancer-controller = {
    #   name = "aws-load-balancer-controller"
    #   chart = "aws-load-balancer-controller"
    #   repository = "https://aws.github.io/eks-charts"
    #   namespace = "aws-load-balancer-controller"
    # }
  }
}