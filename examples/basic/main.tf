terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# A dedicated build identity: the module will not fall back to the legacy
# Cloud Build service account, which holds broad project-wide roles.
resource "google_service_account" "build" {
  project      = var.project_id
  account_id   = "example-trigger-build"
  display_name = "Cloud Build - example-trigger"
}

# Only what this build actually needs. A user-specified build service account
# must be able to write logs or the build refuses to start; builds that push
# images additionally need roles/artifactregistry.writer on the target repo.
resource "google_project_iam_member" "build_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build.email}"
}

module "cloud_build" {
  source = "../.."

  project_id      = var.project_id
  name            = "example-trigger"
  github_owner    = "example-org"
  github_name     = "example-repo"
  branch_regex    = "^main$"
  filename        = "cloudbuild.yaml"
  service_account = google_service_account.build.email
}

variable "project_id" {
  description = "Project ID to deploy the example trigger into."
  type        = string
}

variable "region" {
  description = "Region for the google provider."
  type        = string
  default     = "us-central1"
}

output "trigger_id" {
  value = module.cloud_build.trigger_id
}

output "build_service_account" {
  value = module.cloud_build.service_account
}
