variable "project_id" {
  description = "ID of the project in which to create the build trigger."
  type        = string
}

variable "name" {
  description = "Name of the Cloud Build trigger."
  type        = string
}

variable "description" {
  description = "Description of the trigger."
  type        = string
  default     = "Managed by Terraform"
}

variable "filename" {
  description = "Path to the Cloud Build config file within the source repository."
  type        = string
  default     = "cloudbuild.yaml"
}

variable "github_owner" {
  description = "Owner of the connected GitHub repository."
  type        = string
}

variable "github_name" {
  description = "Name of the connected GitHub repository."
  type        = string
}

variable "branch_regex" {
  description = "Regular expression matching branches that trigger a build."
  type        = string
  default     = "^main$"
}

variable "included_files" {
  description = "Glob patterns; a build is only triggered when a matching file changes. Empty triggers on any change."
  type        = list(string)
  default     = []
}

variable "substitutions" {
  description = "Substitution variables passed to the build."
  type        = map(string)
  default     = {}
}
