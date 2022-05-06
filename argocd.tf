locals {
  system_argocd_projects = {}
  argocd_projects = merge(local.system_argocd_projects, var.argocd_projects)
}

resource "kubernetes_manifest" "argocd" {
  for_each = local.argocd_projects

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name = each.value.metadata.name
      namespace = each.value.metadata.namespace
      labels = try(each.value.metadata.labels, {})
    }

    spec = {
      project = each.value.spec.project
      source = {
        chart = each.value.spec.source.chart
        repoURL = each.value.spec.source.repoURL
        targetRevision = each.value.spec.source.targetRevision
        helm = {
          releaseName = each.value.spec.source.helm.releaseName
        }
      }
      destination = {
        server = each.value.spec.destination.server
        namespace = each.value.spec.destination.namespace
      }
    }
  }
}