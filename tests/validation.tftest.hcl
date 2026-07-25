# Requires Terraform >= 1.7 for mock_provider (test-only; the module itself
# still supports >= 1.5).

mock_provider "google" {}

variables {
  project_id      = "example-project"
  name            = "deploy-main"
  github_owner    = "example-org"
  github_name     = "example-repo"
  service_account = "builder@example-project.iam.gserviceaccount.com"
}

run "rejects_service_account_that_is_not_an_identity" {
  command = plan

  variables {
    service_account = "builder"
  }

  expect_failures = [var.service_account]
}

run "rejects_project_number_as_project_id" {
  command = plan

  variables {
    project_id = "123456789012"
  }

  expect_failures = [var.project_id]
}

# A pattern that never matches is the quiet failure mode: the trigger applies
# cleanly and then never fires.
run "rejects_branch_regex_with_refs_prefix" {
  command = plan

  variables {
    branch_regex = "^refs/heads/main$"
  }

  expect_failures = [var.branch_regex]
}

run "rejects_uncompilable_branch_regex" {
  command = plan

  variables {
    branch_regex = "^[main$"
  }

  expect_failures = [var.branch_regex]
}

run "rejects_empty_branch_regex" {
  command = plan

  variables {
    branch_regex = ""
  }

  expect_failures = [var.branch_regex]
}

run "rejects_padded_branch_regex" {
  command = plan

  variables {
    branch_regex = " ^main$ "
  }

  expect_failures = [var.branch_regex]
}

run "rejects_included_file_pattern_that_matches_nothing" {
  command = plan

  variables {
    included_files = ["/src/**"]
  }

  expect_failures = [var.included_files]
}

run "rejects_malformed_substitution_key" {
  command = plan

  variables {
    substitutions = { environment = "staging" }
  }

  expect_failures = [var.substitutions]
}

run "rejects_secret_shaped_substitution" {
  command = plan

  variables {
    substitutions = { _DEPLOY_TOKEN = "not-a-real-token" }
  }

  expect_failures = [var.substitutions]
}

run "rejects_absolute_filename" {
  command = plan

  variables {
    filename = "/cloudbuild.yaml"
  }

  expect_failures = [var.filename]
}

run "rejects_repo_url_instead_of_owner" {
  command = plan

  variables {
    github_owner = "https://github.com/example-org"
  }

  expect_failures = [var.github_owner]
}

run "rejects_owner_slash_repo_as_name" {
  command = plan

  variables {
    github_name = "example-org/example-repo"
  }

  expect_failures = [var.github_name]
}

run "rejects_invalid_trigger_name" {
  command = plan

  variables {
    name = "1-deploy main"
  }

  expect_failures = [var.name]
}
