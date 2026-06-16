mock_provider "google" {}

mock_provider "databricks" {
  alias = "account"
}

variables {
  project_id      = "my-test-project"
  resource_prefix = "myprefix"
  delegate_emails = []
}

# ── Variable validation tests ──────────────────────────────────────────────────

run "invalid_project_id_rejected" {
  command = plan

  variables {
    project_id = "INVALID_PROJECT"
  }

  expect_failures = [var.project_id]
}

run "project_id_too_short_rejected" {
  command = plan

  variables {
    project_id = "ab"
  }

  expect_failures = [var.project_id]
}

run "project_id_starts_with_digit_rejected" {
  command = plan

  variables {
    project_id = "1bad-project"
  }

  expect_failures = [var.project_id]
}

run "resource_prefix_with_uppercase_rejected" {
  command = plan

  variables {
    resource_prefix = "MyPrefix"
  }

  expect_failures = [var.resource_prefix]
}

run "resource_prefix_too_long_rejected" {
  command = plan

  variables {
    # 21 chars — exceeds the 20-char limit
    resource_prefix = "this-prefix-is-too-long"
  }

  expect_failures = [var.resource_prefix]
}

# ── Resource attribute checks ──────────────────────────────────────────────────

run "service_account_id_uses_prefix_suffix" {
  command = plan

  assert {
    condition     = google_service_account.this.account_id == "myprefix-dbx-provisioner"
    error_message = "Service account ID should be <resource_prefix>-dbx-provisioner"
  }
}

run "service_account_project_matches_input" {
  command = plan

  assert {
    condition     = google_service_account.this.project == "my-test-project"
    error_message = "Service account project should match project_id input"
  }
}

run "custom_role_normalises_hyphens" {
  command = plan

  variables {
    resource_prefix = "my-prefix"
  }

  assert {
    condition     = google_project_iam_custom_role.this.role_id == "my_prefixDbxProvisionerRole"
    error_message = "Custom role ID should replace hyphens with underscores"
  }
}

run "custom_role_no_hyphen_prefix_unchanged" {
  command = plan

  assert {
    condition     = google_project_iam_custom_role.this.role_id == "myprefixDbxProvisionerRole"
    error_message = "Custom role ID without hyphens should stay unchanged"
  }
}

run "databricks_user_role_is_account_admin" {
  command = plan

  assert {
    condition     = databricks_user_role.this.role == "account_admin"
    error_message = "databricks_user_role should assign the account_admin role"
  }
}

run "delegate_members_created_for_each_email" {
  command = plan

  variables {
    delegate_emails = ["user:alice@example.com", "serviceAccount:ci@my-test-project.iam.gserviceaccount.com"]
  }

  assert {
    condition     = length(google_service_account_iam_member.delegate) == 2
    error_message = "One google_service_account_iam_member should be created per delegate email"
  }
}

run "no_delegates_creates_no_members" {
  command = plan

  assert {
    condition     = length(google_service_account_iam_member.delegate) == 0
    error_message = "Empty delegate_emails should create no google_service_account_iam_member resources"
  }
}
