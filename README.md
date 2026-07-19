# terraform-google-cloud-build

Terraform module that manages a [Google Cloud](https://cloud.google.com/)
Cloud Build trigger (`google_cloudbuild_trigger`). It creates a trigger that
starts a build from a config file when a push matches a branch on a connected
GitHub repository.

## Usage

```hcl
module "cloud_build" {
  source = "github.com/moveeeax/terraform-google-cloud-build"

  project_id   = var.project_id
  name         = "deploy-main"
  github_owner = "my-org"
  github_name  = "my-repo"
  branch_regex = "^main$"
  filename     = "cloudbuild.yaml"
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| google    | >= 5.0   |

## Inputs

| Name            | Description                                              | Type           | Default                  | Required |
|-----------------|----------------------------------------------------------|----------------|--------------------------|:--------:|
| `project_id`    | ID of the project in which to create the trigger.        | `string`       | n/a                      |   yes    |
| `name`          | Name of the Cloud Build trigger.                         | `string`       | n/a                      |   yes    |
| `description`   | Description of the trigger.                              | `string`       | `"Managed by Terraform"` |    no    |
| `filename`      | Path to the Cloud Build config file.                     | `string`       | `"cloudbuild.yaml"`      |    no    |
| `github_owner`  | Owner of the connected GitHub repository.               | `string`       | n/a                      |   yes    |
| `github_name`   | Name of the connected GitHub repository.                | `string`       | n/a                      |   yes    |
| `branch_regex`  | Regular expression matching branches that build.        | `string`       | `"^main$"`               |    no    |
| `included_files`| Glob patterns that scope which changes trigger a build. | `list(string)` | `[]`                     |    no    |
| `substitutions` | Substitution variables passed to the build.             | `map(string)`  | `{}`                     |    no    |

## Outputs

| Name         | Description                        |
|--------------|------------------------------------|
| `id`         | Identifier of the build trigger.  |
| `trigger_id` | Unique id of the build trigger.   |
| `name`       | Name of the build trigger.        |

## License

[MIT](LICENSE)
