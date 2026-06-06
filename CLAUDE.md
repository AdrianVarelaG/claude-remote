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
devcontainer/              # Dockerfile for the browser IDE (code-server) image
repositories/              # Git submodules — one per project
```

## TrueNAS Host Layout (after playbook runs)

Everything lives inside the `claude` user's home (`~` = `/mnt/applications/claude-remote/claude`):

```
~/                       # claude user home — owned by claude:claude
  runtime/               # Node.js, Claude Code binary, jq
  claude-config/         # Claude Code settings (settings.json, statusline.sh)
  repositories/          # Git submodules — one per project
  repo/                  # This config repo (claude-remote) cloned on the host
  .claude -> claude-config/  # Symlink so Claude Code finds its config
  .ssh/                  # SSH keys (id_ed25519 used by dev containers for git)
  .oh-my-zsh/  .zshrc    # Shell config deployed by host_shell role
```

## Key Commands

```bash
# Run the full playbook from the Mac (after filling inventory.ini)
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml

# Run only one role (e.g., after editing the template)
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --tags devcontainers

# Add a new project
git submodule add <repo-url> repositories/<name>
# (.gitmodules is auto-created by git on first submodule add)
# Then add an entry to ansible/group_vars/all.yml under `projects:`
# Then re-run the playbook
```

## What NOT to Edit Directly

- **`~/repo/docker-compose.yml`** on TrueNAS — rendered by Ansible from `ansible/roles/devcontainers/templates/docker-compose.yml.j2`; local edits will be overwritten on the next playbook run
- **`~/claude-config/settings.json`** on TrueNAS — deployed by the `claude_config` role; edit `ansible/roles/claude_config/files/settings.json` instead (or the template if it uses variables)

## Dev Container Profiles

The rendered `docker-compose.yml` lives in `~/repo/` on TrueNAS and uses Compose profiles:

```bash
cd ~/repo

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
