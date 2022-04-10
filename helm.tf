data "template_file" "efs_csi_driver_values" {
  template = file("${path.module}/template_values_files/aws-efs-csi-driver.yaml.tpl")
  vars = {
    role_arn = "${module.eks_iam_role.service_account_role_arn}"
    service_account_name = "${local.efs_csi_driver_sa_name}"
    file_system_id = "${aws_efs_file_system.this.id}"
  }
}

data "template_file" "alb_ingress_controller_values" {
  template = file("${path.module}/template_values_files/aws-alb-ingress-controller.yaml.tpl")
  vars = {
    role_arn = "${module.eks_iam_role_alb.service_account_role_arn}"
    service_account_name = "${local.alb_ingress_controller_sa_name}"
    cluster_name = "${module.eks_cluster.eks_cluster_id}"
  }
}

locals {
  argocd_namespace = "argocd"
#   elastic_stack_namespace = "elastic-system"
  efs_csi_driver_sa_name = "aws-efs-csi-controller"
  alb_ingress_controller_sa_name = "aws-alb-ingress-controller"
  system_helm_charts = {
    argocd = {
      name = "argocd"
      chart = "argo-cd"
      repository = "https://argoproj.github.io/argo-helm"
      namespace = local.argocd_namespace
      create_namespace = true
      version = "3.35.2"
      values = [
        file("${path.module}/values_files/argocd_values.yaml")
      ]
    }
    # elasticsearch = {
    #   name = "elasticsearch"
    #   chart = "elasticsearch"
    #   repository = "https://helm.elastic.co"
    #   namespace = local.elastic_stack_namespace
    #   create_namespace = true
    #   version = "7.17.1"
    #   values = [
    #     file("${path.module}/values_files/elasticsearch.yaml")
    #   ]
    # }
    # kibana = {
    #   name = "kibana"
    #   chart = "kibana"
    #   repository = "https://helm.elastic.co"
    #   namespace = local.elastic_stack_namespace
    #   create_namespace = true
    #   version = "7.17.1"
    #   values = [
    #     file("${path.module}/values_files/kibana.yaml")
    #   ]
    # }
    # filebeat = {
    #   name = "filebeat"
    #   chart = "filebeat"
    #   repository = "https://helm.elastic.co"
    #   namespace = local.elastic_stack_namespace
    #   create_namespace = true
    #   version = "7.17.1"
    #   values = [
    #     file("${path.module}/values_files/filebeat.yaml")
    #   ]
    # }
    # kube-prometheus-stack = {
    #   name = "kube-prometheus-stack"
    #   chart = "kube-prometheus-stack"
    #   repository = "https://prometheus-community.github.io/helm-charts"
    #   namespace = "kube-prometheus-stack"
    #   create_namespace = true
    #   version = "23.3.1"
    #   values = [
    #     file("${path.module}/values_files/kube_prometheus_stack.yaml")
    #   ]
    # }
    # metrics-server = {
    #   name = "metrics-server"
    #   chart = "metrics-server"
    #   repository = "https://kubernetes-sigs.github.io/metrics-server/"
    #   namespace = "metrics-server"
    #   create_namespace = true
    #   version = "3.8.2"
    # }
    zimagi = {
      name = "zimagi"
      chart = "zimagi"
      repository = "https://zimagi.github.io/charts"
      namespace = "zimagi"
      create_namespace = true
      version = "1.0.38"
      values = [
        file("${path.module}/values_files/zimagi_values.yaml")
      ]
    }
    efs-csi-driver = {
      name = "aws-efs-csi-driver"
      chart = "aws-efs-csi-driver"
      repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
      namespace = "kube-system"
      version = "2.2.4"
      values = [
        data.template_file.efs_csi_driver_values.rendered
      ]
    }
    cert_manager = {
      name = "cert-manager"
      chart = "cert-manager"
      repository = "https://charts.jetstack.io"
      namespace = "cert-manager"
      create_namespace = true
      version = "1.8.0"
      sets = {
        crds = {
          name = "installCRDs"
          value = "true"
        }
      }
    }
    aws_load_balancer_controller = {
      name = "aws-load-balancer-controller"
      chart = "aws-load-balancer-controller"
      repository = "https://aws.github.io/eks-charts"
      namespace = "kube-system"
      version = "1.4.1"
      values = [
        data.template_file.alb_ingress_controller_values.rendered
      ]
    }
  }
}

locals {
  helm_charts = merge(local.system_helm_charts, var.custom_helm_charts)
}
