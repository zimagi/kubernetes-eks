variable "region" {
  description = "Region of the remote backend"
  type        = string
}

variable "namespace" {
  description = "Prefix name of the remote backend"
  type        = string
}

variable "stage" {
  description = "Environemnt name of the remote backend"
  type        = string
}

variable "terraform_backend_config_file_path" {
  description = "Path of the state file"
  type        = string
  default     = "."
}

variable "terraform_backend_config_file_name" {
  description = "Name of the state file"
  type        = string
  default     = "backend.tf"
}

variable "force_destroy" {
  type    = bool
  default = false
}

locals {
  attributes = ["state"]
}

provider "aws" {
  region = var.region
}

module "terraform_state_backend" {
  source     = "cloudposse/tfstate-backend/aws"
  version    = "0.33.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = "terraform"
  attributes = ["state"]

  terraform_backend_config_file_path = var.terraform_backend_config_file_path
  terraform_backend_config_file_name = var.terraform_backend_config_file_name
  force_destroy                      = var.force_destroy

  prevent_unencrypted_uploads = false
}

output "s3_bucket_name" {
  description = "Name of the remote state bucket"
  value       = join("-", [var.namespace, var.stage, "terraform", join("-", local.attributes)])
}

output "terraform_backend_config_file_path" {
  value = var.terraform_backend_config_file_path
}

output "terraform_backend_file_name" {
  description = "Name of the remote backend file"
  value       = var.terraform_backend_config_file_name
}