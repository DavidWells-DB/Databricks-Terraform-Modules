mock_provider "google" {}

variables {
  host_project_id     = "my-host-project"
  service_project_ids = ["my-service-project"]
  subnet_iam_grants   = []
}

# ---------------------------------------------------------------------------
# Resource attribute checks
# ---------------------------------------------------------------------------

run "host_project_resource_uses_input_project_id" {
  command = plan

  assert {
    condition     = google_compute_shared_vpc_host_project.this.project == "my-host-project"
    error_message = "Shared VPC host project resource should use the host_project_id input"
  }
}

run "service_project_attachment_references_host_project" {
  command = plan

  assert {
    condition     = google_compute_shared_vpc_service_project.this["my-service-project"].host_project == "my-host-project"
    error_message = "Service project attachment should reference the host project"
  }
}

run "service_project_attachment_uses_service_project_id" {
  command = plan

  assert {
    condition     = google_compute_shared_vpc_service_project.this["my-service-project"].service_project == "my-service-project"
    error_message = "Service project attachment should use the service project ID as the service_project attribute"
  }
}

# ---------------------------------------------------------------------------
# Multiple service project for_each
# ---------------------------------------------------------------------------

run "multiple_service_projects_create_multiple_attachments" {
  command = plan

  variables {
    service_project_ids = ["service-project-one", "service-project-two"]
  }

  assert {
    condition     = length(google_compute_shared_vpc_service_project.this) == 2
    error_message = "Two service project IDs should create two google_compute_shared_vpc_service_project resources"
  }
}

# ---------------------------------------------------------------------------
# Subnet IAM grant creation
# ---------------------------------------------------------------------------

run "subnet_iam_grants_create_iam_member_resources" {
  command = plan

  variables {
    subnet_iam_grants = [
      {
        subnetwork = "databricks-subnet"
        region     = "us-central1"
        member     = "serviceAccount:sa@my-service-project.iam.gserviceaccount.com"
        role       = "roles/compute.networkUser"
      }
    ]
  }

  assert {
    condition     = length(google_compute_subnetwork_iam_member.this) == 1
    error_message = "One subnet IAM grant entry should create one google_compute_subnetwork_iam_member resource"
  }
}

run "subnet_iam_grant_project_is_host_project" {
  command = plan

  variables {
    subnet_iam_grants = [
      {
        subnetwork = "databricks-subnet"
        region     = "us-central1"
        member     = "serviceAccount:sa@my-service-project.iam.gserviceaccount.com"
        role       = "roles/compute.networkUser"
      }
    ]
  }

  assert {
    condition = (
      google_compute_subnetwork_iam_member.this["databricks-subnet/us-central1/serviceAccount:sa@my-service-project.iam.gserviceaccount.com/roles/compute.networkUser"].project
      == "my-host-project"
    )
    error_message = "Subnet IAM grant should target the host project"
  }
}

run "no_subnet_iam_grants_creates_no_iam_resources" {
  command = plan

  variables {
    subnet_iam_grants = []
  }

  assert {
    condition     = length(google_compute_subnetwork_iam_member.this) == 0
    error_message = "Empty subnet_iam_grants should create no google_compute_subnetwork_iam_member resources"
  }
}

run "multiple_subnet_iam_grants_all_created" {
  command = plan

  variables {
    subnet_iam_grants = [
      {
        subnetwork = "subnet-a"
        region     = "us-central1"
        member     = "serviceAccount:sa@my-service-project.iam.gserviceaccount.com"
        role       = "roles/compute.networkUser"
      },
      {
        subnetwork = "subnet-b"
        region     = "us-central1"
        member     = "serviceAccount:sa@my-service-project.iam.gserviceaccount.com"
        role       = "roles/compute.networkUser"
      }
    ]
  }

  assert {
    condition     = length(google_compute_subnetwork_iam_member.this) == 2
    error_message = "Two subnet IAM grant entries should create two google_compute_subnetwork_iam_member resources"
  }
}

# ---------------------------------------------------------------------------
# Variable validation: host_project_id
# ---------------------------------------------------------------------------

run "invalid_host_project_id_rejected_spaces" {
  command = plan

  variables {
    host_project_id = "invalid project id"
  }

  expect_failures = [var.host_project_id]
}

run "invalid_host_project_id_rejected_uppercase" {
  command = plan

  variables {
    host_project_id = "Invalid-Project"
  }

  expect_failures = [var.host_project_id]
}

run "invalid_host_project_id_rejected_too_short" {
  command = plan

  variables {
    host_project_id = "ab"
  }

  expect_failures = [var.host_project_id]
}

# ---------------------------------------------------------------------------
# Variable validation: service_project_ids
# ---------------------------------------------------------------------------

run "empty_service_project_ids_rejected" {
  command = plan

  variables {
    service_project_ids = []
  }

  expect_failures = [var.service_project_ids]
}

run "invalid_service_project_id_rejected" {
  command = plan

  variables {
    service_project_ids = ["valid-project-id", "INVALID_ID"]
  }

  expect_failures = [var.service_project_ids]
}
