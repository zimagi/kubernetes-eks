region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "eg"

stage = "test"

name = "eks"

kubernetes_version = "1.19"

map_additional_iam_users = [{
  userarn  = "arn:aws:iam::137919228019:user/circleci"
  username = "circleci"
  groups   = []
}]

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
    disk_size = 40
  }
}