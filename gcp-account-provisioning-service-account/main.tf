# GCP service account used by Databricks to provision workspace compute resources.
resource "google_service_account" "this" {
  account_id   = local.service_account_id
  display_name = local.service_account_display_name
  project      = var.project_id
}

# Custom IAM role granting Databricks the minimum permissions required to provision
# GKE-based workspaces: compute management, KMS decryption, GKE node pool operations,
# and Shared VPC subnet usage.
# Permission set sourced from:
# https://docs.databricks.com/gcp/en/admin/account-settings-gcp/credentials.html
resource "google_project_iam_custom_role" "this" {
  project     = var.project_id
  role_id     = local.custom_role_id
  title       = "Databricks Workspace Provisioner (${var.resource_prefix})"
  description = "Minimum permissions for the Databricks control plane to provision GKE-based workspaces."
  permissions = [
    # Compute — manage instances, disks, firewalls, networks needed by workspace nodes.
    "compute.disks.create",
    "compute.disks.delete",
    "compute.disks.get",
    "compute.disks.list",
    "compute.disks.setLabels",
    "compute.disks.use",
    "compute.firewalls.create",
    "compute.firewalls.delete",
    "compute.firewalls.get",
    "compute.firewalls.list",
    "compute.firewalls.update",
    "compute.globalOperations.get",
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.getIamPolicy",
    "compute.instances.list",
    "compute.instances.setIamPolicy",
    "compute.instances.setLabels",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.instances.setTags",
    "compute.instances.start",
    "compute.instances.stop",
    "compute.instances.update",
    "compute.networks.get",
    "compute.networks.list",
    "compute.networks.use",
    "compute.networks.useExternalIp",
    "compute.projects.get",
    "compute.regionOperations.get",
    "compute.regions.get",
    "compute.regions.list",
    "compute.routes.list",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.zoneOperations.get",
    "compute.zones.get",
    "compute.zones.list",
    # KMS — decrypt workspace storage if customer-managed encryption keys are used.
    "cloudkms.cryptoKeyVersions.useToDecrypt",
    "cloudkms.cryptoKeyVersions.useToEncrypt",
    # GKE — create and manage GKE clusters and node pools for workspace compute.
    "container.clusters.create",
    "container.clusters.delete",
    "container.clusters.get",
    "container.clusters.getCredentials",
    "container.clusters.list",
    "container.clusters.update",
    "container.operations.get",
    "container.operations.list",
    # Shared VPC — required when the workspace network lives in a host project.
    "compute.subnetworks.getIamPolicy",
    "compute.subnetworks.setIamPolicy",
    # IAM — allow Databricks to bind the node service account to GKE node pools.
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
    # Service usage — required for Databricks to verify enabled APIs.
    "serviceusage.services.get",
    "serviceusage.services.list",
  ]
}

# Bind the custom role to the provisioner service account at the project level.
resource "google_project_iam_member" "this" {
  project = var.project_id
  role    = google_project_iam_custom_role.this.name
  member  = "serviceAccount:${google_service_account.this.email}"
}

# Allow the listed delegate_emails to impersonate the provisioner service account.
# Typically used by human operators or CI/CD pipelines during bootstrapping.
resource "google_service_account_iam_member" "delegate" {
  for_each = toset(var.delegate_emails)

  service_account_id = google_service_account.this.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = each.value
}

# Register the GCP service account email as a Databricks account-level user.
# The Databricks provider treats GCP service accounts as users identified by their email.
resource "databricks_user" "this" {
  provider  = databricks.account
  user_name = google_service_account.this.email
}

# Grant the service account the account_admin role so it can provision workspaces.
resource "databricks_user_role" "this" {
  provider = databricks.account
  user_id  = databricks_user.this.id
  role     = "account_admin"
}
