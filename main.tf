resource "google_cloudbuild_trigger" "this" {
  project        = var.project_id
  name           = var.name
  description    = var.description
  filename       = var.filename
  included_files = var.included_files
  substitutions  = var.substitutions

  github {
    owner = var.github_owner
    name  = var.github_name

    push {
      branch = var.branch_regex
    }
  }
}
