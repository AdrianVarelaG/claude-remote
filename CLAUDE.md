# CLAUDE.md

This file provides guidance to Claude Code sessions working in this repository.

## What This Repo Is

Master configuration for all dev projects on TrueNAS SCALE — an Ansible playbook run from a Mac provisions and maintains everything idempotently on the host.

## Repo Layout

```
ansible/
  group_vars/all.yml       # All tunables: pool path, projects list, ports, UIDs
  inventory.ini            # TrueNAS host IP (fill before first run)
  playbook.yml             # Top-level playbook; runs roles in order
  roles/                   # dataset, runtime, host_shell, claude_config, repos, devcontainers
  templates/
    docker-compose.yml.j2  # Jinja2 template — rendered to docker-compose.yml by Ansible
devcontainer/              # Dockerfile for the browser IDE (code-server) image
repositories/              # Git submodules — one per project
```

## Key Commands

```bash
# Run the full playbook from the Mac (after filling inventory.ini)
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml

# Run only one role (e.g., after editing the template)
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --tags devcontainers

# Add a new project
git submodule add <repo-url> repositories/<name>
# Then add an entry to ansible/group_vars/all.yml under `projects:`
# Then re-run the playbook
```

## What NOT to Edit Directly

- **`docker-compose.yml`** — rendered by Ansible from `ansible/templates/docker-compose.yml.j2`; local edits will be overwritten on the next playbook run
- **`/mnt/applications/claude-remote/claude-config/settings.json`** on TrueNAS — deployed by the `claude_config` role; edit `ansible/roles/claude_config/files/settings.json` instead

## Dev Container Profiles

The rendered `docker-compose.yml` uses Compose profiles. On TrueNAS:

```bash
# Start ALL repositories in a single container (profile: all)
docker compose --profile all up -d

# Start only a specific project (profile matches project name)
docker compose --profile xml-pdf up -d

# Stop everything
docker compose down
```

## Adding a Project

1. `git submodule add <repo-url> repositories/<name>`
2. Add an entry under `projects:` in `ansible/group_vars/all.yml` (name + port)
3. Re-run the playbook — it renders a new docker-compose.yml and clones the submodule on the host
