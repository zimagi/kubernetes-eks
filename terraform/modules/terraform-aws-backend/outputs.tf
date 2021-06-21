output "s3_bucket_domain_name" {
  value = module.terraform_state_backend.s3_bucket_domain_name
}

output "s3_bucket_id" {
  description = "Name of the remote state bucket"
  value       = module.terraform_state_backend.s3_bucket_id
}

output "dynamodb_table_name" {
  value = module.terraform_state_backend.dynamodb_table_name
}

output "dynamodb_table_id" {
  value = module.terraform_state_backend.dynamodb_table_id
}

output "terraform_backend_config_file_path" {
  value = var.terraform_backend_config_file_path
}

output "terraform_backend_config_file_name" {
  description = "Name of the remote backend file"
  value       = var.terraform_backend_config_file_name
}

output "terraform_backend_config" {
  value = module.terraform_state_backend.terraform_backend_config
}