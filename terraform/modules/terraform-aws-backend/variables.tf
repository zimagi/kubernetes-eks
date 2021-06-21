variable "region" {
  description = "Region of the remote backend"
  type        = string
}

variable "stage" {
  description = "Environemnt name of the remote backend"
  type        = string
}

variable "namespace" {
  type        = string
  description = "Prefix of resources"
}

variable "name" {
  type = string
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

variable "terraform_state_file" {
  type        = string
  description = "Name of the tfstate file"
  default     = "backend.tfstate"
}

variable "force_destroy" {
  type    = bool
  default = false
}