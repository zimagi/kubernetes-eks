provider "aws" {
  region = var.region
}


module "terraform_state_backend" {
  source     = "cloudposse/tfstate-backend/aws"
  version    = "0.33.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  attributes = ["state"]

  terraform_backend_config_file_path = var.terraform_backend_config_file_path
  terraform_backend_config_file_name = var.terraform_backend_config_file_name
  force_destroy                      = var.force_destroy
  terraform_state_file               = var.terraform_state_file

  prevent_unencrypted_uploads = false
}
