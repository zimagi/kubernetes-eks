serviceAccount:
  name: ${service_account_name}
  annotations:
      eks.amazonaws.com/role-arn: ${role_arn}
clusterName: ${cluster_name}