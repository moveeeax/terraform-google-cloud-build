locals {
  # The API stores the build identity as a full resource name. Accept either
  # form from the caller and normalise, so a bare e-mail does not fail at apply.
  service_account = startswith(var.service_account, "projects/") ? var.service_account : "projects/${var.project_id}/serviceAccounts/${var.service_account}"
}

resource "google_cloudbuild_trigger" "this" {
  project        = var.project_id
  name           = var.name
  description    = var.description
  filename       = var.filename
  included_files = var.included_files
  substitutions  = var.substitutions

  # Without this the build runs as the legacy Cloud Build service account,
  # which carries broad project-wide roles. Required, never defaulted.
  service_account = local.service_account

  github {
    owner = var.github_owner
    name  = var.github_name

    push {
      branch = var.branch_regex
    }
  }
}
