module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_version = var.eks_cluster_version
  cluster_name    = var.eks_cluster_name
  subnets         = module.vpc.private_subnets

  tags = var.eks_cluster_tags

  vpc_id = module.vpc.vpc_id

  workers_group_defaults = var.workers_group_defaults

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.medium"
      asg_desired_capacity          = 3
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    }
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}