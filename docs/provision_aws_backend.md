# Provision aws backend for terraform state file

Terraform module `modules/terraform-aws-backend` to provision an S3 bucket to store terraform.tfstate file and a DynamoDB table to lock the state file to prevent concurrent modifications and state corruption.

The module supports the following:

- Forced server-side encryption at rest for the S3 bucket
- S3 bucket versioning to allow for Terraform state recovery in the case of accidental deletions and human errors
- State locking and consistency checking via DynamoDB table to prevent concurrent operations
- DynamoDB server-side encryption

You can find more about [s3](https://www.terraform.io/docs/backends/types/s3.html) backend.

> NOTE: The operators of the module (IAM Users) must have permissions to create S3 buckets and DynamoDB tables when performing terraform plan and terraform apply

### Create IAM User
Before we can do anything with terraform, we need to authenticate. The simplest way to do that is to build an IAM user in AWS.
- Login AWS Console
- Open `IAM Service`
- Click on `Users`, then click on `Add User`
- Fill User name and check `Programmatic access`, then click on `Next: Permissions`
- Attach existing policy `AdministratorAccess`, then click on `Next: Tags`
- Click on `Next: Review`
- Click on `Create User`
- Download file credential and setup as github secret

### Provision aws backend

Run github action [workflow](https://github.com/zimagi/kubernetes-eks/actions/workflows/provision_terraform_backend.yml)