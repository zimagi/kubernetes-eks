region = "us-east-2"

availability_zones = ["us-east-2a", "us-east-2b"]

namespace = "eg"

stage = "test"

name = "eks"

kubernetes_version = "1.20"

map_additional_iam_users = [{
  userarn  = "arn:aws:iam::251788601858:user/erik.jagyugya@dccs.tech"
  username = "erik.jagyugya@dccs.tech"
  groups   = []
}]

node_groups = {
  t3_medium_compute = {
    name = ""
    instance_types = ["t3.medium"]
    desired_size   = 1
    min_size       = 1
    max_size       = 3
    kubernetes_labels = {}
    disk_size = 40
  }
  t3_medium_gpu_compute = {
    instance_types = ["t3.medium"]
    desired_size   = 0
    min_size       = 0
    max_size       = 3
    kubernetes_labels = {}
    disk_size = 40
  }
}