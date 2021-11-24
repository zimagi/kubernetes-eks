provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  autoscaler_serviceaccount_name = "cluster-autoscaler"
}


data "template_file" "values" {
  template = "${file("${path.module}/templates/values.yaml.tpl")}"
  vars = {
    autoDiscovery_clusterName = module.eks.eks_cluster_name
    awsRegion = var. region
    image_tag = "v${var.kubernetes_version}.0"
    rbac_serviceAccount_annotations_eks_role = module.eks.autoscaler_role_service_account_role_arn
    rbac_serviceAccount_name = local.autoscaler_serviceaccount_name
  }
}

module "eks" {
  source                            = "../.."
  region                            = var.region
  availability_zones = var.availability_zones
  kubernetes_version                = var.kubernetes_version
  local_exec_interpreter            = var.local_exec_interpreter
  oidc_provider_enabled             = var.oidc_provider_enabled
  enabled_cluster_log_types         = var.enabled_cluster_log_types
  cluster_log_retention_period      = var.cluster_log_retention_period
  kubeconfig_path_enabled           = var.kubeconfig_path_enabled
  kubeconfig_path                   = var.kubeconfig_path
  map_additional_aws_accounts       = var.map_additional_aws_accounts
  map_additional_iam_roles          = var.map_additional_iam_roles
  map_additional_iam_users          = var.map_additional_iam_users
  cluster_encryption_config_enabled = var.cluster_encryption_config_enabled
  node_groups                       = var.node_groups
  cluster_autoscaler_enabled = var.cluster_autoscaler_enabled
  aws_account_number = data.aws_caller_identity.current.id
  service_account_name = local.autoscaler_serviceaccount_name

  helm_charts = {
    metric-server = {
      name = "metrics-server"
      chart = "metrics-server"
      repository = "https://kubernetes-sigs.github.io/metrics-server/"
      namespace = "kube-system"
    }
    cluster-autoscaler = {
      name = "aws-cluster-autoscaler"
      chart = "cluster-autoscaler"
      repository = "https://kubernetes.github.io/autoscaler"
      namespace = "kube-system"
      values = [data.template_file.values.rendered]
    }
    # aws-load-balancer-controller = {
    #   name = "aws-load-balancer-controller"
    #   chart = "aws-load-balancer-controller"
    #   repository = "https://aws.github.io/eks-charts"
    #   namespace = "aws-load-balancer-controller"
    # }
  }
}