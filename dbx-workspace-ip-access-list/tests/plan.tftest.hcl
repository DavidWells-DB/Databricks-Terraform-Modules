mock_provider "databricks" {
  alias = "workspace"
}

variables {
  allow_list_cidrs = ["10.0.0.0/8", "192.168.1.0/24"]
  allow_list_label = "corporate-networks"
  block_list_cidrs = null
  block_list_label = "block-list"
}

# ── Allow-only configuration ────────────────────────────────────────────────

run "allow_only_creates_allow_list" {
  command = plan

  assert {
    condition     = databricks_ip_access_list.allow.list_type == "ALLOW"
    error_message = "Allow list resource must have list_type = ALLOW"
  }

  assert {
    condition     = databricks_ip_access_list.allow.label == "corporate-networks"
    error_message = "Allow list label should match the allow_list_label input"
  }

  assert {
    condition     = databricks_ip_access_list.allow.enabled == true
    error_message = "Allow list must be enabled"
  }
}

run "allow_only_no_block_list" {
  command = plan

  assert {
    condition     = length(databricks_ip_access_list.block) == 0
    error_message = "No block list resource should be created when block_list_cidrs is null"
  }
}

run "block_list_id_output_is_null_without_block_list" {
  command = plan

  assert {
    condition     = output.block_list_id == null
    error_message = "block_list_id output should be null when no block list is configured"
  }
}

# ── Allow + Block configuration ─────────────────────────────────────────────

run "with_block_list_creates_block_resource" {
  command = plan

  variables {
    block_list_cidrs = ["198.51.100.0/24"]
    block_list_label = "blocked-ranges"
  }

  assert {
    condition     = length(databricks_ip_access_list.block) == 1
    error_message = "One block list resource should be created when block_list_cidrs is non-null"
  }

  assert {
    condition     = databricks_ip_access_list.block[0].list_type == "BLOCK"
    error_message = "Block list resource must have list_type = BLOCK"
  }

  assert {
    condition     = databricks_ip_access_list.block[0].label == "blocked-ranges"
    error_message = "Block list label should match the block_list_label input"
  }

  assert {
    condition     = databricks_ip_access_list.block[0].enabled == true
    error_message = "Block list must be enabled"
  }
}

# ── workspace_conf ───────────────────────────────────────────────────────────

run "workspace_conf_enables_ip_access_lists" {
  command = plan

  assert {
    condition     = databricks_workspace_conf.this.custom_config["enableIpAccessLists"] == "true"
    error_message = "workspace_conf must set enableIpAccessLists = true"
  }
}

# ── Variable validation: allow_list_cidrs ────────────────────────────────────

run "empty_allow_list_cidrs_rejected" {
  command = plan

  variables {
    allow_list_cidrs = []
  }

  expect_failures = [var.allow_list_cidrs]
}

run "invalid_cidr_format_in_allow_list_rejected" {
  command = plan

  variables {
    allow_list_cidrs = ["not-an-ip-address"]
  }

  expect_failures = [var.allow_list_cidrs]
}

run "valid_single_ip_in_allow_list_accepted" {
  command = plan

  variables {
    allow_list_cidrs = ["203.0.113.42"]
  }

  assert {
    condition     = length(databricks_ip_access_list.block) == 0
    error_message = "Single IP without prefix length should be accepted"
  }
}

# ── Variable validation: block_list_cidrs ────────────────────────────────────

run "empty_block_list_cidrs_list_rejected" {
  command = plan

  variables {
    block_list_cidrs = []
  }

  expect_failures = [var.block_list_cidrs]
}

run "invalid_cidr_format_in_block_list_rejected" {
  command = plan

  variables {
    block_list_cidrs = ["not-a-valid-ip"]
  }

  expect_failures = [var.block_list_cidrs]
}

# ── Variable validation: label lengths ──────────────────────────────────────

run "empty_allow_list_label_rejected" {
  command = plan

  variables {
    allow_list_label = ""
  }

  expect_failures = [var.allow_list_label]
}

run "empty_block_list_label_rejected" {
  command = plan

  variables {
    block_list_label = ""
  }

  expect_failures = [var.block_list_label]
}
