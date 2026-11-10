output "guard_addresses" {
  description = "Map of guard key to its full resource address hint (for audit + the documented state-rm escape path). The caller's module call name completes the address."
  value       = { for k, _ in var.guards : k => "module.<call>.terraform_data.guard[\"${k}\"]" }
}

output "notice_addresses" {
  description = "Map of notice key to its resource address hint."
  value       = { for k, _ in var.notices : k => "module.<call>.terraform_data.notice[\"${k}\"]" }
}
