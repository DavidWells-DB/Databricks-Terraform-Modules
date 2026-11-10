variables {
  guards = {
    "csp_enabled_marker" = {
      current       = true
      error_message = "CSP was enabled and is IRREVERSIBLE; keep it on. Escape: state rm this marker."
    }
    "protection_armed_marker" = {
      current       = false
      error_message = "Destroy protection was armed; cannot disarm by tfvars. Escape: state rm."
    }
  }
  notices = {
    "lockdown_notice" = {
      message = "NETWORK-PERIMETER WARNING: public access off; Terraform needs in-perimeter access."
    }
  }
}

run "guards_and_notices_created_per_entry" {
  command = plan

  assert {
    condition     = length(terraform_data.guard) == 2 && length(terraform_data.notice) == 1
    error_message = "One terraform_data per guard and per notice entry"
  }
}

run "notice_is_non_blocking_text" {
  command = plan

  assert {
    condition     = terraform_data.notice["lockdown_notice"].input == "NETWORK-PERIMETER WARNING: public access off; Terraform needs in-perimeter access."
    error_message = "Notices record their message as plan-visible input"
  }
}

run "guard_addresses_hint_the_escape_path" {
  command = plan

  assert {
    condition     = output.guard_addresses["csp_enabled_marker"] == "module.<call>.terraform_data.guard[\"csp_enabled_marker\"]"
    error_message = "The address hint names the documented state-rm escape path"
  }
}

# --- guard direction semantics: state carries between runs in one test file. ----------
# (false recorded flipping to true is legal growth; false->false is a no-op.)

run "guard_records_true_on_first_apply" {
  command = apply

  assert {
    condition     = terraform_data.guard["csp_enabled_marker"].output == true
    error_message = "First apply must record the current value (true)"
  }
}

run "guard_flip_true_to_false_fails_the_apply" {
  # plan-command: the postcondition fires at PLAN stage (that is the whole point —
  # fail before apply, not after). terraform test marks apply-command runs with
  # expect_failures as failed when the failure blocks the apply; plan + expect_failures
  # is the supported shape.
  command = plan

  variables {
    guards = {
      "csp_enabled_marker" = {
        current       = false
        error_message = "csp_enabled_marker: CSP was enabled and is IRREVERSIBLE; keep it on. Escape: state rm this marker."
      }
      "protection_armed_marker" = {
        current       = false
        error_message = "Destroy protection was armed; cannot disarm by tfvars. Escape: state rm."
      }
    }
    notices = {
      "lockdown_notice" = {
        message = "NETWORK-PERIMETER WARNING: public access off; Terraform needs in-perimeter access."
      }
    }
  }

  # The recorded value is true (frozen); current is now false — the postcondition
  # (current || !self.input) must fail this apply.
  expect_failures = [terraform_data.guard]
}
