output "public_subnet_cidrs" {
  value       = module.eks.public_subnet_cidrs
  description = "Public subnet CIDRs"
}

output "private_subnet_cidrs" {
  value       = module.eks.private_subnet_cidrs
  description = "Private subnet CIDRs"
}

output "vpc_cidr" {
  value       = module.eks.vpc_cidr
  description = "VPC ID"
}

output "eks_cluster_arn" {
  value       = module.eks.eks_cluster_arn
  description = "The Amazon Resource Name (ARN) of the cluster"
}

output "eks_cluster_certificate_authority_data" {
  value     = module.eks.eks_cluster_certificate_authority_data
  sensitive = true
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_id" {
  description = "The name of the cluster"
  value       = module.eks.eks_cluster_id
}

output "eks_cluster_identity_oidc_issuer" {
  description = "The OIDC Identity issuer for the cluster"
  value       = module.eks.eks_cluster_identity_oidc_issuer
}

output "eks_cluster_identity_oidc_issuer_arn" {
  value       = module.eks.eks_cluster_identity_oidc_issuer_arn
  description = "The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account"
}

output "eks_cluster_managed_security_group_id" {
  description = "Security Group ID that was created by EKS for the cluster. EKS creates a Security Group and applies it to ENI that is attached to EKS Control Plane master nodes and to any managed workloads"
  value       = module.eks.eks_cluster_managed_security_group_id
}

output "eks_cluster_role_arn" {
  value       = module.eks.eks_cluster_role_arn
  description = "ARN of the EKS cluster IAM role"
}

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster Security Group"
  value       = module.eks.eks_cluster_security_group_id
}

output "eks_cluster_security_group_name" {
  description = "Name of the EKS cluster Security Group"
  value       = module.eks.eks_cluster_security_group_name
}

output "eks_cluster_security_group_arn" {
  description = "ARN of the EKS cluster Security Group"
  value       = module.eks.eks_cluster_security_group_arn
}

output "eks_cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = module.eks.eks_cluster_version
}

output "eks_cluster_name" {
  value = module.eks.eks_cluster_id
}

output "kubernetes_config_map_id" {
  value       = module.eks.kubernetes_config_map_id
  description = "kubernetes_config_map_id	ID of aws-auth Kubernetes ConfigMap"
}

output "subnet_ids" {
  value       = module.eks.subnet_ids
  description = "Subnet IDs"
}

# output "efs" {
#   value = module.eks.efs
# }


# output "eks_node_group_arn" {
#   description = "Amazon Resource Name (ARN) of the EKS Node Group"
#   value       = 
# }

# output "eks_node_group_cbd_pet_name" {
#   value       = module.eks.eks_node_group_cbd_pet_name
#   description = "The pet name of this node group, if this module generated one"
# }

# output "eks_node_group_id" {
#   description = "EKS Cluster name and EKS Node Group name separated by a colon"
#   value       = module.eks.eks_node_group_id
# }

# output "eks_node_group_remote_access_security_group_id" {
#   value       = module.eks.eks_node_group_remote_access_security_group_id
#   description = "The ID of the security group generated to allow SSH access to the nodes, if this module generated one"
# }

# output "eks_node_group_resources" {
#   description = "List of objects containing information about underlying resources of the EKS Node Group"
#   value       = module.eks.eks_node_group_resources
# }

# output "eks_node_group_role_arn" {
#   description = "ARN of the worker nodes IAM role"
#   value       = module.eks.eks_node_group_role_arn
# }

# output "eks_node_group_role_name" {
#   description = "Name of the worker nodes IAM role"
#   value       = module.eks.eks_node_group_role_name
# }

# output "eks_node_group_status" {
#   description = "Status of the EKS Node Group"
#   value       = module.eks.eks_node_group_status
# }