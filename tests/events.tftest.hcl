# Requires Terraform >= 1.7 for mock_provider (test-only; the module itself
# still supports >= 1.5).

mock_provider "google" {}

variables {
  project_id      = "example-project"
  name            = "plan-pr"
  github_owner    = "example-org"
  github_name     = "example-repo"
  service_account = "builder@example-project.iam.gserviceaccount.com"
}

# Upgrading must not change the plan of an existing push-on-branch trigger.
run "default_is_still_push_on_branch" {
  command = plan

  assert {
    condition     = length(google_cloudbuild_trigger.this.github[0].push) == 1 && length(google_cloudbuild_trigger.this.github[0].pull_request) == 0
    error_message = "Without event/pull_request the trigger must stay a push trigger with no pull_request block."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].push[0].branch == "^main$" && google_cloudbuild_trigger.this.github[0].push[0].tag == null
    error_message = "The default push trigger must match ^main$ on branches and set no tag pattern."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].push[0].invert_regex == null
    error_message = "The default push trigger must not start setting invert_regex."
  }
}

run "pull_request_trigger_with_safe_comment_default" {
  command = plan

  variables {
    event        = "pull_request"
    pull_request = { branch = "^main$" }
  }

  assert {
    condition     = length(google_cloudbuild_trigger.this.github[0].push) == 0 && length(google_cloudbuild_trigger.this.github[0].pull_request) == 1
    error_message = "event = pull_request must render only the pull_request block."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].pull_request[0].branch == "^main$"
    error_message = "pull_request.branch must reach the trigger."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].pull_request[0].comment_control == "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
    error_message = "Outside contributors' pull requests must wait for a /gcbrun comment unless the caller opts out."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].pull_request[0].invert_regex == false
    error_message = "invert_regex must default to false."
  }
}

run "pull_request_trigger_passes_options_through" {
  command = plan

  variables {
    event = "pull_request"
    pull_request = {
      branch          = "^release/.+$"
      comment_control = "COMMENTS_ENABLED"
      invert_regex    = true
    }
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].pull_request[0].comment_control == "COMMENTS_ENABLED"
    error_message = "pull_request.comment_control must reach the trigger."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].pull_request[0].invert_regex == true
    error_message = "pull_request.invert_regex must reach the trigger."
  }
}

run "push_on_tags" {
  command = plan

  variables {
    tag_regex = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].push[0].tag == "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
    error_message = "tag_regex must reach the push filter."
  }

  assert {
    condition     = google_cloudbuild_trigger.this.github[0].push[0].branch == null
    error_message = "The API accepts only one of branch or tag, so branch must be unset when tag_regex is."
  }
}

run "rejects_pull_request_event_without_filter" {
  command = plan

  variables {
    event = "pull_request"
  }

  expect_failures = [google_cloudbuild_trigger.this]
}

run "rejects_pull_request_filter_on_push_event" {
  command = plan

  variables {
    pull_request = { branch = "^main$" }
  }

  expect_failures = [google_cloudbuild_trigger.this]
}

run "rejects_tag_regex_on_pull_request_event" {
  command = plan

  variables {
    event        = "pull_request"
    pull_request = { branch = "^main$" }
    tag_regex    = "^v.*$"
  }

  expect_failures = [google_cloudbuild_trigger.this]
}

run "rejects_unknown_event" {
  command = plan

  variables {
    event = "tag"
  }

  expect_failures = [var.event]
}

run "rejects_unknown_comment_control" {
  command = plan

  variables {
    event        = "pull_request"
    pull_request = { branch = "^main$", comment_control = "ALWAYS" }
  }

  expect_failures = [var.pull_request]
}

run "rejects_pull_request_branch_with_refs_prefix" {
  command = plan

  variables {
    event        = "pull_request"
    pull_request = { branch = "^refs/heads/main$" }
  }

  expect_failures = [var.pull_request]
}

run "rejects_uncompilable_pull_request_branch" {
  command = plan

  variables {
    event        = "pull_request"
    pull_request = { branch = "^[main$" }
  }

  expect_failures = [var.pull_request]
}

run "rejects_empty_pull_request_branch" {
  command = plan

  variables {
    event        = "pull_request"
    pull_request = { branch = "" }
  }

  expect_failures = [var.pull_request]
}

run "rejects_tag_regex_with_refs_prefix" {
  command = plan

  variables {
    tag_regex = "^refs/tags/v.*$"
  }

  expect_failures = [var.tag_regex]
}

run "rejects_uncompilable_tag_regex" {
  command = plan

  variables {
    tag_regex = "^v[0-9$"
  }

  expect_failures = [var.tag_regex]
}

run "rejects_empty_tag_regex" {
  command = plan

  variables {
    tag_regex = ""
  }

  expect_failures = [var.tag_regex]
}
