autoDiscovery:
  clusterName: ${cluster_name}
cloudProvider: aws
awsRegion: ${aws_region}
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: ${role_arn}
  name: ${service_account_name}