controller:
  serviceAccount:
    name: ${service_account_name}
    annotations:
      eks.amazonaws.com/role-arn: ${role_arn}
storageClasses:
  - name: efs-sc
    mountOptions:
    - tls
    parameters:
      provisioningMode: efs-ap
      fileSystemId: ${file_system_id}
      directoryPerms: "700"
      gidRangeStart: "1000"
      gidRangeEnd: "2000"
      basePath: "/dynamic_provisioning"
    reclaimPolicy: Delete
    volumeBindingMode: Immediate

