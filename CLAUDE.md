# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A Docker Compose setup that runs multiple isolated code-server (browser-accessible VS Code) containers, each with Claude Code pre-installed. The host's `~/.claude` directory is shared into every container so credentials and settings persist across rebuilds.

## Container Services

| Service | Port | Workspace mounted from host | Purpose |
|---|---|---|---|
| `workspace-base` | 8080 | `./` (this repo) | General base container |
| `workspace-python` | 8081 | `../proyectos/python` | Python dev (pyright, black) |
| `workspace-nextjs` | — | `../proyectos/nextjs` | Next.js dev (TypeScript LSP, ESLint, Prettier, Tailwind) |
| `workspace-node` | 8082 | `../proyectos/xml-pdf` | Node/Puppeteer dev |

## Key Commands

```bash
# Start all containers
docker compose up -d

# Rebuild after Dockerfile changes
docker compose up -d --build

# Start a single service
docker compose up -d workspace-python

# View logs
docker compose logs -f workspace-python

# Stop everything
docker compose down
```

## Configuration Architecture

- **`docker-compose.yml`** — defines services, volume mounts, port mappings, and the `WORKSPACE_PASSWORD` env var (read from `.env`)
- **`<service>/Dockerfile`** — installs language tooling + Claude Code globally; UID/GID are parameterized to `950:950` to match the TrueNAS host user
- **`<service>/settings.json`** — mounted at `/workspace/.claude/settings.json` inside each container; controls Claude's allowed/denied Bash commands and enabled LSP plugins
- **`.ssh-contenedor/`** — SSH known_hosts and a generated keypair for the container identity; the host's private key is additionally bind-mounted read-only at `/home/coder/.ssh/id_ed25519`

## Claude Permissions Per Container

- **Python**: allows `python3`, `pip`, `pytest`, `uvicorn`, `black`, `git`, read commands; denies `rm -rf`, `curl`, `wget`
- **Next.js / Node**: allows `npm`, `npx`, `node`, `next`, `eslint`, `prettier`, `tsc`, `git`, read commands; denies `rm -rf`, `curl`, `wget`

## Keeping Claude Running After Disconnect

Use `tmux` inside any container's code-server terminal:

```bash
tmux new -s claude
claude  # or claude remote-control --name "..."
# Ctrl+B, D to detach
tmux attach -t claude
```

## Adding a New Container

1. Create `<name>/Dockerfile` following the existing pattern (base image `codercom/code-server:latest`, install tools, install `@anthropic-ai/claude-code` globally)
2. Create `<name>/settings.json` with appropriate permission allowlist
3. Add the service to `docker-compose.yml`, mounting `../.claude`, the project directory, a named config volume, `<name>/settings.json`, and `.ssh-contenedor`
