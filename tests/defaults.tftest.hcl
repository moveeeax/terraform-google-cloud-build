# Requires Terraform >= 1.7 for mock_provider (test-only; the module itself
# still supports >= 1.5). Runs offline with no credentials:
#   terraform test

mock_provider "google" {}

variables {
  project_id      = "example-project"
  name            = "deploy-main"
  github_owner    = "example-org"
  github_name     = "example-repo"
  service_account = "builder@example-project.iam.gserviceaccount.com"
}

run "build_identity_is_explicit_and_normalised" {
  assert {
    condition     = google_cloudbuild_trigger.this.service_account == "projects/example-project/serviceAccounts/builder@example-project.iam.gserviceaccount.com"
    error_message = "A bare service account e-mail must be normalised to the full resource name so the build never falls back to the legacy Cloud Build service account."
  }
}

run "accepts_full_resource_name_unchanged" {
  variables {
    service_account = "projects/other-project/serviceAccounts/builder@other-project.iam.gserviceaccount.com"
  }

  assert {
    condition     = google_cloudbuild_trigger.this.service_account == "projects/other-project/serviceAccounts/builder@other-project.iam.gserviceaccount.com"
    error_message = "A service account already given as a full resource name must be passed through untouched."
  }
}

run "defaults_are_narrow" {
  assert {
    condition     = google_cloudbuild_trigger.this.github[0].push[0].branch == "^main$"
    error_message = "The default branch filter must be anchored to main only, not a catch-all that lets any branch push run a build."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.filename == "cloudbuild.yaml"
    error_message = "Default build config file changed."
  }

  assert {
    condition     = length(google_cloudbuild_trigger.this.substitutions) == 0
    error_message = "No substitutions should be set by default."
  }
}

run "wires_repository_and_filters_through" {
  variables {
    branch_regex   = "^release/.+$"
    included_files = ["src/**", "cloudbuild.yaml"]
    substitutions  = { _ENVIRONMENT = "staging" }
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].owner == "example-org" && google_cloudbuild_trigger.this.github[0].name == "example-repo"
    error_message = "GitHub owner/name must reach the trigger."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].push[0].branch == "^release/.+$"
    error_message = "branch_regex must reach the push filter."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.included_files == tolist(["src/**", "cloudbuild.yaml"])
    error_message = "included_files must reach the trigger."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.substitutions["_ENVIRONMENT"] == "staging"
    error_message = "substitutions must reach the trigger."
  }
}
