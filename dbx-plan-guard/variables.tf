variable "guards" {
  type = map(object({
    current       = bool
    error_message = string
  }))
  description = <<-EOT
    One-time-direction guards, keyed by a caller-chosen name. Each entry records `current`
    at FIRST apply and freezes it; when the recorded value is true and `current` later
    flips to false, the plan FAILS with `error_message`. Use for API-irreversible
    capabilities (CSP, disable-legacy-dbfs) and armed sentinels (destroy protection).
    Name your module call in error_message so operators see the exact state-rm escape
    path: terraform state rm 'module.<call>.terraform_data.guard["<key>"]'.
  EOT
  default     = {}
  nullable    = false
}

variable "notices" {
  type = map(object({
    message = string
  }))
  description = <<-EOT
    Plan-visible, non-blocking notices, keyed by a caller-chosen name. Use for warnings
    that must surface in the plan (e.g. the network-perimeter lockdown manageability
    warning) without failing it.
  EOT
  default     = {}
  nullable    = false
}
