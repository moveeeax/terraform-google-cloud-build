# terraform-google-cloud-build

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Cloud Build trigger (`google_cloudbuild_trigger`). It creates a trigger that
starts a build from a config file when a push matches a branch on a connected
GitHub repository.

## Usage

```hcl
resource "google_service_account" "build" {
  project    = var.project_id
  account_id = "deploy-main-build"
}

resource "google_project_iam_member" "build_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build.email}"
}

module "cloud_build" {
  source = "github.com/moveeeax/terraform-google-cloud-build"

  project_id      = var.project_id
  name            = "deploy-main"
  github_owner    = "my-org"
  github_name     = "my-repo"
  branch_regex    = "^main$"
  filename        = "cloudbuild.yaml"
  service_account = google_service_account.build.email
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Security notes

A build runs arbitrary code from the repository with the permissions of its
build identity, so a few things matter more here than in a typical module.

- **`service_account` is required.** If it is left unset, Cloud Build falls back
  to the legacy per-project service account
  (`[PROJECT_NUMBER]@cloudbuild.gserviceaccount.com`), which is granted broad
  project-wide roles such as `roles/cloudbuild.builds.builder`. Every build then
  inherits them. Give each trigger a dedicated service account holding only the
  permissions that build needs, and grant the Terraform principal
  `roles/iam.serviceAccountUser` on it.
- **A user-specified build identity must be able to write logs.** When
  `service_account` is set, Cloud Build refuses to start the build unless the
  build config sends logs somewhere: set `options.logging: CLOUD_LOGGING_ONLY`
  (and grant `roles/logging.logWriter`) or set `logsBucket` in your
  `cloudbuild.yaml`.
- **Substitutions are not secrets.** Values in `substitutions` are stored on the
  trigger, kept in Terraform state, and echoed into build logs. Reference Secret
  Manager through `availableSecrets` in the build config instead. The module
  rejects substitution keys that look like credentials.
- **Filters are validated.** A branch pattern that matches nothing produces a
  trigger that applies cleanly and then never fires, which is easy to miss. The
  module rejects empty, whitespace-padded, uncompilable and `refs/heads/`-prefixed
  patterns, and `included_files` globs that cannot match. It cannot tell you that
  an otherwise-valid pattern is too broad: `branch_regex` is a partial RE2 match,
  so anchor it (`^main$`, not `main`).
- **Pull request triggers are deliberately not supported.** This module only
  creates push-on-branch triggers, so an outside contributor cannot run code with
  the build identity by opening a pull request. If you add a pull request trigger
  elsewhere, set `comment_control` so builds require a maintainer's `/gcbrun`.

Build behaviour that is defined in the config file, not on the trigger -
`machine_type`, `timeout`, artifact and image destinations - is out of this
module's reach; it lives in your `cloudbuild.yaml`.

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

The test suite additionally needs Terraform >= 1.7 for `mock_provider`; the
module itself does not.

## Inputs

| Name             | Description                                                                          | Type           | Default                  | Required |
|------------------|--------------------------------------------------------------------------------------|----------------|--------------------------|:--------:|
| `project_id`     | ID of the project in which to create the trigger.                                    | `string`       | n/a                      |   yes    |
| `name`           | Name of the Cloud Build trigger.                                                     | `string`       | n/a                      |   yes    |
| `service_account`| Identity the build runs as. Bare e-mail or `projects/{p}/serviceAccounts/{email}`.    | `string`       | n/a                      |   yes    |
| `github_owner`   | Owner of the connected GitHub repository.                                            | `string`       | n/a                      |   yes    |
| `github_name`    | Name of the connected GitHub repository.                                             | `string`       | n/a                      |   yes    |
| `description`    | Description of the trigger.                                                          | `string`       | `"Managed by Terraform"` |    no    |
| `filename`       | Path to the Cloud Build config file, relative to the repository root.                | `string`       | `"cloudbuild.yaml"`      |    no    |
| `branch_regex`   | RE2 pattern matched against the pushed branch name.                                  | `string`       | `"^main$"`               |    no    |
| `included_files` | Glob patterns that scope which changes trigger a build.                              | `list(string)` | `[]`                     |    no    |
| `substitutions`  | Substitution variables passed to the build. Not for secrets.                         | `map(string)`  | `{}`                     |    no    |

## Outputs

| Name              | Description                                                  |
|-------------------|--------------------------------------------------------------|
| `id`              | Identifier of the build trigger.                             |
| `trigger_id`      | Unique id of the build trigger.                              |
| `name`            | Name of the build trigger.                                   |
| `service_account` | Full resource name of the identity builds run as.            |

## Testing

```sh
terraform test
```

The suite in [`tests/`](tests) uses a mocked provider, so it needs no
credentials and no network access.

## License

[MIT](LICENSE)
