region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "eg"

stage = "test"

name = "eks"

kubernetes_version = "1.19"

oidc_provider_enabled = true

enabled_cluster_log_types = []

cluster_log_retention_period = 7

instance_types = ["t3.small"]

desired_size = 2

max_size = 3

min_size = 2

disk_size = 20

kubernetes_labels = {}

# cluster_encryption_config_enabled = false

cluster_autoscaler_enabled = true

node_groups = {
  t3_small_core = {
    instance_types = ["t3.small"]
    desired_size   = 1
    min_size       = 1
    max_size       = 3
    kubernetes_labels = {
      zimagi = "core"
    }
    disk_size = 40
  }
  t3_small_worker = {
    instance_types = ["t3.small"]
    desired_size   = 0
    min_size       = 0
    max_size       = 3
    kubernetes_labels = {
      zimagi = "worker"
    }
    disk_size     = 40
  }
}