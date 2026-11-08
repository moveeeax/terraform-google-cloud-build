# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `event` (`"push"` or `"pull_request"`, default `"push"`) and `pull_request`
  (`branch`, `comment_control`, `invert_regex`) for pull request triggers.
  `comment_control` defaults to `COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY`.
- `tag_regex` (default `null`) to fire a push trigger on tags instead of
  branches.
- Validation for the new patterns (non-empty, compilable, no `refs/` prefix)
  and preconditions that reject `pull_request` or `tag_regex` on the wrong event.
  Existing deployments plan the same.

### Changed

- CI: bump actions to their current majors, pin tool versions, and restrict the
  workflow token to `contents: read`.
- CI: add Dependabot for GitHub Actions and the Terraform provider.
- Docs: pin the README usage `source` to a release tag; fix the LICENSE year.

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-google-cloud-build/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/moveeeax/terraform-google-cloud-build/releases/tag/v1.0.0
