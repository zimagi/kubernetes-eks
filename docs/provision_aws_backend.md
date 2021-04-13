# Provision aws backend for terraform state file

## AWS Backend
Before we can do anything with terraform, we need to authenticate. The simplest way to do that is to build an IAM user in AWS.
- Login AWS Console
- Open `IAM Service`
- Click on `Users`, then click on `Add User`
- Fill User name and check `Programmatic access`, then click on `Next: Permissions`
- Attach existing policy `AdministratorAccess`, then click on `Next: Tags`
- Click on `Next: Review`
- Click on `Create User`
- Download file credential