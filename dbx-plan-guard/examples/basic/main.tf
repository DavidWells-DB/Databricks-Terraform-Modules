terraform {
  required_version = ">= 1.7.0"
}

module "guards" {
  source = "../.."

  guards = {
    csp_enabled = {
      current       = true
      error_message = "CSP was enabled and is IRREVERSIBLE. Keep it on, or replace the workspace. Escape: terraform state rm 'module.guards.terraform_data.guard[\"csp_enabled\"]'."
    }
  }

  notices = {
    lockdown = {
      message = "NETWORK-PERIMETER WARNING: public access is off; Terraform reaches this workspace only from inside the perimeter."
    }
  }
}
