autoDiscovery:
  clusterName: ${autoDiscovery_clusterName}

awsRegion: ${awsRegion}

image:
  tag: ${image_tag}

rbac:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ${rbac_serviceAccount_annotations_eks_role}
    name: ${rbac_serviceAccount_name}

cloudProvider: aws