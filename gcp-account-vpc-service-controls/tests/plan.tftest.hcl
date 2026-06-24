mock_provider "google" {}

variables {
  access_policy_id          = "123456789012"
  perimeter_name            = "test_perimeter"
  perimeter_title           = "Test Perimeter"
  protected_project_numbers = ["987654321098"]
  restricted_services       = ["storage.googleapis.com", "bigquery.googleapis.com"]
}

run "perimeter_name_matches_input" {
  command = plan

  assert {
    condition     = output.perimeter_name == "test_perimeter"
    error_message = "Perimeter name should match the perimeter_name input"
  }
}

run "perimeter_name_too_long_rejected" {
  command = plan

  variables {
    perimeter_name = "this_perimeter_name_is_way_too_long_and_exceeds_fifty_characters"
  }

  expect_failures = [var.perimeter_name]
}

run "perimeter_name_invalid_chars_rejected" {
  command = plan

  variables {
    perimeter_name = "invalid-name-with-hyphens"
  }

  expect_failures = [var.perimeter_name]
}

run "perimeter_name_with_spaces_rejected" {
  command = plan

  variables {
    perimeter_name = "invalid name with spaces"
  }

  expect_failures = [var.perimeter_name]
}

run "perimeter_title_empty_rejected" {
  command = plan

  variables {
    perimeter_title = ""
  }

  expect_failures = [var.perimeter_title]
}

run "perimeter_title_too_long_rejected" {
  command = plan

  variables {
    perimeter_title = "This is a very long title that exceeds the maximum allowed length of two hundred characters for a service perimeter title and should therefore be rejected by the validation rule that we have in place to prevent excessively long titles from being used"
  }

  expect_failures = [var.perimeter_title]
}

run "protected_projects_empty_rejected" {
  command = plan

  variables {
    protected_project_numbers = []
  }

  expect_failures = [var.protected_project_numbers]
}

run "normalized_projects_formats_correctly" {
  command = plan

  variables {
    protected_project_numbers = ["987654321098", "projects/876543210987"]
  }

  assert {
    condition     = length(output.protected_projects) == 2
    error_message = "Should have two protected projects"
  }

  assert {
    condition     = contains(output.protected_projects, "projects/987654321098")
    error_message = "First project should be normalized to projects/987654321098"
  }

  assert {
    condition     = contains(output.protected_projects, "projects/876543210987")
    error_message = "Second project should remain as projects/876543210987"
  }
}

run "restricted_services_applied" {
  command = plan

  assert {
    condition     = length(output.restricted_services) == 2
    error_message = "Should have two restricted services"
  }

  assert {
    condition     = contains(output.restricted_services, "storage.googleapis.com")
    error_message = "Should include storage.googleapis.com in restricted services"
  }

  assert {
    condition     = contains(output.restricted_services, "bigquery.googleapis.com")
    error_message = "Should include bigquery.googleapis.com in restricted services"
  }
}

run "custom_restricted_services_applied" {
  command = plan

  variables {
    restricted_services = ["compute.googleapis.com", "container.googleapis.com"]
  }

  assert {
    condition     = length(output.restricted_services) == 2
    error_message = "Should have two custom restricted services"
  }

  assert {
    condition     = contains(output.restricted_services, "compute.googleapis.com")
    error_message = "Should include compute.googleapis.com in restricted services"
  }

  assert {
    condition     = contains(output.restricted_services, "container.googleapis.com")
    error_message = "Should include container.googleapis.com in restricted services"
  }
}
