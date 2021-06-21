provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

terraform {
  backend "s3" {
    bucket = "zimagi-terraform-remote-backend"
    key    = "remote_bucket_key"
    region = "us-east-2"
  }
}

provider "aws" {
  version = ">= 2.28.1"
  region  = "us-east-2"
}