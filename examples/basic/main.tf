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

module "cloud_build" {
  source = "../.."

  project_id   = var.project_id
  name         = "example-trigger"
  github_owner = "example-org"
  github_name  = "example-repo"
  branch_regex = "^main$"
  filename     = "cloudbuild.yaml"
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
