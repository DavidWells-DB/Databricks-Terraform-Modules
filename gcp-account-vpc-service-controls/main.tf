resource "google_access_context_manager_service_perimeter" "this" {
  parent = local.normalized_access_policy
  name   = "${local.normalized_access_policy}/servicePerimeters/${var.perimeter_name}"
  title  = var.perimeter_title

  status {
    resources           = local.normalized_projects
    restricted_services = var.restricted_services
    access_levels       = var.access_levels

    dynamic "ingress_policies" {
      for_each = var.ingress_policies
      content {
        dynamic "ingress_from" {
          for_each = ingress_policies.value.ingress_from != null ? [ingress_policies.value.ingress_from] : []
          content {
            identity_type = ingress_from.value.identity_type
            identities    = ingress_from.value.identities

            dynamic "sources" {
              for_each = ingress_from.value.sources != null ? ingress_from.value.sources : []
              content {
                access_level = sources.value.access_level
                resource     = sources.value.resource
              }
            }
          }
        }

        dynamic "ingress_to" {
          for_each = ingress_policies.value.ingress_to != null ? [ingress_policies.value.ingress_to] : []
          content {
            resources = ingress_to.value.resources

            dynamic "operations" {
              for_each = ingress_to.value.operations != null ? ingress_to.value.operations : []
              content {
                service_name = operations.value.service_name

                dynamic "method_selectors" {
                  for_each = operations.value.method_selectors != null ? operations.value.method_selectors : []
                  content {
                    method     = method_selectors.value.method
                    permission = method_selectors.value.permission
                  }
                }
              }
            }
          }
        }
      }
    }

    dynamic "egress_policies" {
      for_each = var.egress_policies
      content {
        dynamic "egress_from" {
          for_each = egress_policies.value.egress_from != null ? [egress_policies.value.egress_from] : []
          content {
            identity_type = egress_from.value.identity_type
            identities    = egress_from.value.identities
          }
        }

        dynamic "egress_to" {
          for_each = egress_policies.value.egress_to != null ? [egress_policies.value.egress_to] : []
          content {
            resources = egress_to.value.resources

            dynamic "operations" {
              for_each = egress_to.value.operations != null ? egress_to.value.operations : []
              content {
                service_name = operations.value.service_name

                dynamic "method_selectors" {
                  for_each = operations.value.method_selectors != null ? operations.value.method_selectors : []
                  content {
                    method     = method_selectors.value.method
                    permission = method_selectors.value.permission
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
