region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "zimagi"

stage = "develop"

name = "eks"

kubernetes_version = "1.20"

cidr_block = "172.16.0.0/16"

oidc_provider_enabled = true

enabled_cluster_log_types = ["audit"]

cluster_log_retention_period = 7

instance_types = ["t3.medium"]

desired_size = 2

max_size = 3

min_size = 2

disk_size = 20

kubernetes_labels = {}

cluster_encryption_config_enabled = true