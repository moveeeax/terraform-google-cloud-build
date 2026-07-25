variable "project_id" {
  description = "ID of the project in which to create the build trigger."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a project ID (6-30 chars, lowercase letters, digits and hyphens), not a project number or display name."
  }
}

variable "name" {
  description = "Name of the Cloud Build trigger."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,63}$", var.name))
    error_message = "name must start with a letter and contain only letters, digits and hyphens (max 64 characters)."
  }
}

variable "description" {
  description = "Description of the trigger."
  type        = string
  default     = "Managed by Terraform"
}

variable "service_account" {
  description = <<-EOT
    Service account the triggered build runs as. Required: leaving it unset makes
    Cloud Build fall back to the legacy per-project service account
    ([PROJECT_NUMBER]@cloudbuild.gserviceaccount.com), which holds broad
    project-wide roles, so every build gets them too. Give each trigger a
    dedicated identity with only the permissions that build needs.

    Accepts either `projects/{project}/serviceAccounts/{email}` or the bare
    service account e-mail.

    Note: when a build runs as a user-specified service account, the build config
    must send logs somewhere the caller can read - set `options.logging` to
    `CLOUD_LOGGING_ONLY` or set `logsBucket` in the cloudbuild config file, or the
    build fails to start.
  EOT
  type        = string

  validation {
    condition = (
      can(regex("^projects/[^/@ ]+/serviceAccounts/[^/@ ]+@[^/@ ]+$", var.service_account))
      || can(regex("^[^/@ ]+@[^/@ ]+\\.gserviceaccount\\.com$", var.service_account))
    )
    error_message = "service_account must be a service account e-mail (name@project.iam.gserviceaccount.com) or projects/{project}/serviceAccounts/{email}."
  }
}

variable "filename" {
  description = "Path to the Cloud Build config file within the source repository."
  type        = string
  default     = "cloudbuild.yaml"

  validation {
    condition     = length(var.filename) > 0 && !startswith(var.filename, "/") && !startswith(var.filename, "../")
    error_message = "filename must be a non-empty path relative to the repository root (no leading '/' and no '../')."
  }
}

variable "github_owner" {
  description = "Owner of the connected GitHub repository."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{0,38}$", var.github_owner))
    error_message = "github_owner must be a GitHub user or organisation login, not a URL or owner/repo pair."
  }
}

variable "github_name" {
  description = "Name of the connected GitHub repository."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,100}$", var.github_name))
    error_message = "github_name must be the repository name alone, not a URL or owner/repo pair."
  }
}

variable "branch_regex" {
  description = <<-EOT
    RE2 regular expression matched against the pushed branch name. Matching is
    partial, so anchor it (`^main$`) unless you really mean a prefix match. The
    name is matched without the `refs/heads/` prefix.
  EOT
  type        = string
  default     = "^main$"

  validation {
    condition     = length(var.branch_regex) > 0 && var.branch_regex == trimspace(var.branch_regex)
    error_message = "branch_regex must be non-empty and free of leading/trailing whitespace; an empty or padded pattern either matches every branch or never fires."
  }

  validation {
    # regexall returns an empty list on no match and only errors on a bad
    # pattern, so this is a pure syntax check.
    condition     = can(regexall(var.branch_regex, "main"))
    error_message = "branch_regex is not a valid RE2 regular expression."
  }

  validation {
    condition     = !can(regex("refs/(heads|tags)/", var.branch_regex))
    error_message = "branch_regex is matched against the bare branch name, so a pattern containing 'refs/heads/' or 'refs/tags/' never fires. Use '^main$', not '^refs/heads/main$'."
  }
}

variable "included_files" {
  description = "Glob patterns; a build is only triggered when a matching file changes. Empty triggers on any change."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for f in var.included_files : length(trimspace(f)) > 0 && !startswith(f, "/")])
    error_message = "included_files entries must be non-empty repository-relative globs; an empty or '/'-prefixed pattern matches nothing and silently stops the trigger from firing."
  }
}

variable "substitutions" {
  description = <<-EOT
    User-defined substitution variables passed to the build. Keys must start with
    an underscore and use only uppercase letters, digits and underscores.

    Do not put secrets here: substitution values are stored in the trigger, in
    Terraform state, and are visible in the build log. Use Secret Manager via
    `availableSecrets` in the build config instead.
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k in keys(var.substitutions) : can(regex("^_[A-Z0-9_]+$", k))])
    error_message = "Substitution keys must match ^_[A-Z0-9_]+$ (user-defined substitutions start with an underscore and are uppercase)."
  }

  validation {
    condition = alltrue([
      for k in keys(var.substitutions) :
      !can(regex("(PASSWORD|PASSWD|SECRET|_TOKEN|API_KEY|ACCESS_KEY|PRIVATE_KEY|CREDENTIAL)", k))
    ])
    error_message = "Substitution values are stored in plaintext and echoed into build logs. Reference the secret from Secret Manager via 'availableSecrets' in the build config instead of passing it as a substitution."
  }
}
