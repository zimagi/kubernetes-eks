provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "example" {
  name = module.eks.eks_cluster_id
}

data "aws_eks_cluster_auth" "example" {
  name = module.eks.eks_cluster_id
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.example.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.example.token
  }
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