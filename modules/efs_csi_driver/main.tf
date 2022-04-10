resource "aws_security_group" "this" {
    name = var.security_group_name
    description = var.security_group_description
    vpc_id = var.vpc_id
    tags = var.tags

    ingress {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = var.cidr_blocks
    }
}

resource "aws_efs_file_system" "this" {
  creation_token = var.creation_token_name

  tags = var.tags
}

# resource "aws_efs_mount_target" "this" {
#   for_each = toset([for v in var.subnet_ids : tostring(v)])

#   file_system_id = aws_efs_file_system.this.id
#   subnet_id = each.value
#   security_groups = [aws_security_group.this.id]
# }

output "efs_example_fsid" {
  value = aws_efs_file_system.this.id
}

variable "tags" {
    description = ""
    type = map(string)
    default = {}
}

variable "vpc_id" {
    description = ""
    type = string
}

variable "creation_token_name" {
    description = ""
    type = string
}

variable "subnet_ids" {
    description = ""
    type = list(string)
}

variable "security_group_name" {
    description = ""
    type = string
}

variable "security_group_description" {
    description = "Security group for efs volume access."
    type = string
    default = "Security group for efs volume access."
}

variable "cidr_blocks" {
  description = ""
  type = list(string)
}