variable "region" {
  default     = "us-east-2"
  description = "AWS region"
}

variable "remote_bucket_name" {
  description = "Name of the remote s3 bucket"
  type        = string
  default     = "zimagi-terraform-remote-backend"
}

variable "remote_bucket_key" {
  description = "Name of the ley of the s3 bucket"
  type        = string
  default     = "terraform.tfstate"
}

# VPC

variable "vpc_name" {
  description = "Name of the vpc"
  type        = string
  default     = "zimagi"
}

variable "vpc_cidr" {
  description = "CIDR of the vpc"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_private_subnets" {
  description = "List of the private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "vpc_public_subnets" {
  description = "List of the public subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

# EKS

variable "eks_cluster_version" {
  description = "Version of the eks cluster"
  type        = string
  default     = "1.18"
}

variable "eks_cluster_name" {
  description = "Name of the eks cluster"
  type        = string
  default     = "zimagi"
}

variable "eks_cluster_tags" {
  description = "Tags of the eks cluster"
  type        = map(string)
  default     = {}
}

variable "workers_group_defaults" {
  description = "Default Options for worker groups"
  type        = map(string)
  default = {
    root_volume_type = "gp2"
  }
}