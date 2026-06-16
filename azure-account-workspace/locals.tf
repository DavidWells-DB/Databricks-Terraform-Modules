locals {
  # VNet injection is active when virtual_network_id is provided.
  vnet_injection_enabled = var.virtual_network_id != null

  # Extended compliance standards (beyond HIPAA/PCI_DSS/NONE) require an azapi
  # post-creation update. The combined list merges both sets.
  all_compliance_standards = distinct(concat(
    var.compliance_security_profile_standards,
    var.extended_compliance_standards,
  ))

  # The azapi workaround is needed when extended standards are requested.
  azapi_compliance_needed = var.compliance_security_profile_enabled && length(var.extended_compliance_standards) > 0

  # Root DBFS CMK post-creation resource is created only when a key is supplied.
  root_dbfs_cmk_enabled = var.root_dbfs_cmk_key_vault_key_id != null
}
