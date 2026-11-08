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

    # Exactly one of push / pull_request is rendered, chosen by var.event.
    dynamic "push" {
      for_each = var.event == "push" ? [1] : []
      content {
        # A tag pattern switches the push trigger from branches to tags; the
        # API accepts only one of branch or tag.
        branch = var.tag_regex == null ? var.branch_regex : null
        tag    = var.tag_regex
      }
    }

    dynamic "pull_request" {
      for_each = var.event == "pull_request" ? [var.pull_request] : []
      content {
        branch          = pull_request.value.branch
        comment_control = pull_request.value.comment_control
        invert_regex    = pull_request.value.invert_regex
      }
    }
  }

  lifecycle {
    # Cross-variable checks live here rather than in variable validation
    # blocks, which can only reference other variables from Terraform 1.9.
    precondition {
      condition     = var.event != "pull_request" || var.pull_request != null
      error_message = "event = \"pull_request\" needs the pull_request object (at least its base branch pattern)."
    }

    precondition {
      condition     = var.event == "pull_request" || var.pull_request == null
      error_message = "pull_request is set but event is \"push\", so it would be ignored. Set event = \"pull_request\" or drop pull_request."
    }

    precondition {
      condition     = var.event == "push" || var.tag_regex == null
      error_message = "tag_regex only applies to push triggers; a pull_request trigger matches the base branch via pull_request.branch."
    }
  }
}
