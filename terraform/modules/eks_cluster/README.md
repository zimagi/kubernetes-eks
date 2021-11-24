# EKS Cluster

[Components](#components)

## Components
- VPC
  - Network with address range 172.16.0.0/16
- Subnetworks
  - Nat gateway
  - availability_zones
- EKS Cluster
  - Control plane
  - IAM Role to allow the cluster to access other AWS services
  - Security Group which is used by EKS workers to connect to the cluster and kubelets and pods to receive communication from the cluster control plane
  - The module creates and automatically applies an authentication ConfigMap to allow the workers nodes to join the cluster and to add additional users/roles/accounts

### EKS Cluster

#### Authentication

Every Terraform module that provisions an EKS cluster has faced the challenge that access to the cluster is partly controlled by a resource inside the cluster,
a ConfigMap called aws-auth. You need to be able to access the cluster through the Kubernetes API to modify the ConfigMap, because there is no AWS API for it.
This presents a problem: how do you authenticate to an API endpoint that you have not yet created?

- **kubeconfig**: After creating the EKS cluster, terraform put `kubeconfig` file. This file can be used as an artifact with circleci.
- **data source** (default method): An authentication token can be retrieved using the `aws_eks_cluster_auth` data source. Again, this works, as long as the token does not expire while
Terraform is running, and the token is refreshed during the "plan" phase before trying to refresh the state. Unfortunately, failures of both types have been seen.
- **exec**: An authentication token can be retrieved on demand by using the `exec` feature of the Kubernetes provider to call `aws eks get-token`. This requires
 that the aws CLI be installed and available to Terraform and that it has access to sufficient credentials to perform the authentication and is configured to use them.

> Currently, the exec option appears to be the most reliable method, so I recommend using it if possible, but because of the extra requirements it has, data source is the default authentication method.