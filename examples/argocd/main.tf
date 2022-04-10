provider "aws" {
    region = var.region
}

# data "aws_eks_cluster" "this" {
#   name = var.eks_cluster_id
# }
# data "aws_eks_cluster_auth" "this" {
#   name = var.eks_cluster_id
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.this.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_id]
#     command     = "aws"
#   }
# }

provider "kubernetes" {
  config_path = "~/.kube/config"
}

module "argocd" {
  source = "./../../modules/argocd"
}