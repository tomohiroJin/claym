# Contributing to Claym

Thanks for helping improve the Claym development container. This document summarises the expectations for contributors so that reviews and releases stay smooth.

## Getting Started
- Use the provided VS Code Dev Container (`Dev Containers: Reopen in Container`) to ensure you are working inside a reproducible environment.
- After the container boots, run `bash /usr/local/bin/post-create-setup.sh` if you need to re-register MCP servers manually.
- Keep dependencies inside the container image or helper scripts; avoid introducing host-specific requirements.

## Contribution Workflow
1. Search existing issues and discussions before filing a new one.
2. Discuss significant changes in an issue before opening a pull request when possible.
3. Work on a feature branch named `topic/<short-description>` or similar.
4. Keep commits focused and include clear messages that describe the change and rationale.

## Coding Guidelines
- Follow the structure and conventions already used in `.devcontainer/` scripts (Bash with `set -Eeuo pipefail`, helper sourcing, informative logging).
- Prefer portable Shell/POSIX friendly constructs unless the surrounding script already relies on Bash-only features.
- When editing configuration files (e.g. `devcontainer.json`), preserve ordering and comments unless a change is required.
- Update documentation (README or this guide) if behaviour or workflows change.

## Testing and Validation
- Rebuild the Dev Container (`Dev Containers: Rebuild Container`) when you change Dockerfile packages or startup scripts.
- For shell scripts, run `shellcheck` if you have it available, and manually exercise the affected workflows (e.g. container start, MCP registration).
- Confirm that new files are added to the repository in ASCII and with executable bits only where necessary.

## Pull Request Checklist
- [ ] Tests or manual validation steps are described in the PR body.
- [ ] Documentation updates are included when behaviour changes.
- [ ] TODO items linked to the change are marked complete or referenced.
- [ ] The PR references the related issue (if one exists).

We appreciate your time and effort—thank you for contributing!
