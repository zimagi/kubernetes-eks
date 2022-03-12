provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.eks_cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.eks_cluster_id]
      command     = "aws"
    }
  }
}

resource "helm_release" "chart" {
  for_each = local.helm_charts

  name                       = each.value.name
  chart                      = each.value.chart
  repository                 = try(each.value.repository, null)
  namespace                  = try(each.value.namespace, "default")
  verify                     = try(each.value.verify, false)
  timeout                    = try(each.value.timeout, 300)
  disable_webhooks           = try(each.value.disable_webhooks, false)
  reuse_values               = try(each.value.reuse_values, false)
  reset_values               = try(each.value.reset_values, false)
  force_update               = try(each.value.force_update, false)
  recreate_pods              = try(each.value.recreate_pods, false)
  cleanup_on_fail            = try(each.value.cleanup_on_fail, false)
  max_history                = try(each.value.max_history, 0)
  atomic                     = try(each.value.atomic, false)
  render_subchart_notes      = try(each.value.render_subchart_notes, true)
  disable_openapi_validation = try(each.value.disable_openapi_validation, false)
  skip_crds                  = try(each.value.skip_crds, false)
  create_namespace           = try(each.value.create_namespace, false)
  dependency_update          = try(each.value.dependency_update, false)
  disable_crd_hooks          = try(each.value.disable_crd_hooks, false)
  lint                       = try(each.value.lint, false)
  replace                    = try(each.value.replace, false)
  version                    = try(each.value.version, null)
  wait                       = try(each.value.wait, true)
  wait_for_jobs              = try(each.value.wait_for_jobs, false)
  dynamic "set" {
    for_each = try(each.value.sets, [])
    content {
      name  = set.value.name
      value = set.value.value
    }
  }
  dynamic "set_sensitive" {
    for_each = try(each.value.sensitive_sets, [])
    content {
      name  = set_sensitive.value.name
      value = set_sensitive.value.value
    }
  }
  values = try(each.value.values, [])

  depends_on = [
    module.label,
    module.vpc,
    module.subnets,
    module.eks_cluster,
    module.eks_node_group,
  module.autoscaler_role]
}