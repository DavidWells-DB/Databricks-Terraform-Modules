# The shared honesty-layer module — the marker pattern extracted from the six growing
# roots (2026-11-10, H5-5) so it is written once, not copy-pasted per config.
#
# Two mechanisms, deliberately NOT check blocks (checks only WARN; these must FAIL the
# plan so a silently-refused change never looks green):
#
#   1. guards — one-time-direction markers: a terraform_data records the flag's value at
#      FIRST apply and freezes it (ignore_changes). The postcondition fails the plan when
#      the recorded value is true and the current value flips to false — the exact
#      semantics of the in-root csp_enabled_marker / legacy_enabled_marker /
#      protection_armed_marker (the CSP/legacy irreversibility + destroy-sentinel cases).
#
#   2. notices — plan-visible text (count-gated terraform_data, like
#      lockdown_manageability_notice): warnings that must surface in the plan without
#      blocking it.
#
# Deliberate escape hatch (auditable, same as the in-root markers): terraform state rm
# the marker — 'module.<name>.terraform_data.guard["<key>"]'. The caller's error_message
# should name its own module call address so operators see the exact path.

# --- guards: recorded-at-first-apply, frozen, one-direction -----------------------
resource "terraform_data" "guard" {
  for_each = var.guards

  input = each.value.current

  lifecycle {
    # Freeze the recorded value: postconditions compare the CURRENT input against the
    # value captured at first apply.
    ignore_changes = [input]

    postcondition {
      condition     = each.value.current || !self.input
      error_message = each.value.error_message
    }
  }
}

# --- notices: plan-visible, non-blocking -----------------------------------------
resource "terraform_data" "notice" {
  for_each = var.notices

  input = each.value.message
}
