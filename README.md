# Claude Remote Dev Environment

Two isolated development containers (Python and Next.js) with Claude Code accessible remotely from any browser or mobile device via Tailscale.

## Structure

```
claude-remote/
├── docker-compose.yml       # Starts both containers
├── python/
│   ├── Dockerfile           # Python 3 + Pyright LSP + Black + Claude Code
│   └── settings.json        # Claude permissions + pyright-lsp plugin
└── nextjs/
    ├── Dockerfile           # Node 20 + TypeScript LSP + Claude Code
    └── settings.json        # Claude permissions + typescript-lsp plugin
```

## Prerequisites

- Docker and Docker Compose installed on your server
- Tailscale installed and connected on both your server and personal devices
- A claude.ai subscription (Pro, Max, Team, or Enterprise)
- Claude Code v2.1.51+

## First-time Setup

### 1. Authenticate Claude Code on the server (outside Docker, one time only)

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

This opens an OAuth flow in your browser. Your credentials are saved to `~/.claude/` and will be shared with the containers via a volume mount.

### 2. Clone this repository on your server

```bash
git clone <this-repo> claude-remote
cd claude-remote
```

### 3. Set your passwords

Edit `docker-compose.yml` and replace `tu-password-seguro` with your chosen passwords for both services.

### 4. Set up your project directories

```bash
mkdir -p ~/proyectos/python
mkdir -p ~/proyectos/nextjs
```

Clone your repos into each:

```bash
git clone git@github.com:your-org/python-repo.git ~/proyectos/python
git clone git@github.com:your-org/nextjs-repo.git ~/proyectos/nextjs
```

### 5. Load your SSH key

```bash
eval $(ssh-agent -s)
ssh-add ~/.ssh/your-private-key
```

### 6. Start the containers

```bash
docker compose up -d --build
```

## Accessing the Environment

### From browser (code-server)

| Container | URL |
|-----------|-----|
| Python    | `http://<tailscale-ip>:8080` |
| Next.js   | `http://<tailscale-ip>:8081` |

Enter the password you set in `docker-compose.yml`.

### From mobile (assign tasks to Claude)

1. Open `claude.ai` on your phone
2. Go to the **Code** tab
3. You will see your active remote sessions listed
4. Tap a session to assign tasks, check progress, or give new instructions

### Starting Claude remote control

Open a terminal inside code-server and run:

```bash
claude remote-control --name "Python Workspace"
# or
claude remote-control --name "Next.js Workspace"
```

Your session will appear in `claude.ai/code` within seconds.

## LSP Code Intelligence

Each container has its language server installed and configured for Claude:

| Container | LSP Plugin | Provides |
|-----------|------------|----------|
| Python    | `pyright-lsp@claude-plugins-official` | Type checking, go-to-definition, find-references |
| Next.js   | `typescript-lsp@claude-plugins-official` | Type checking, go-to-definition, find-references |

Claude uses these automatically to navigate and understand your code. The first time you start Claude Code in a container it may prompt you to confirm the plugin installation.

## Managing Containers

```bash
# Start both
docker compose up -d

# Stop both
docker compose down

# Start only Python
docker compose up -d workspace-python

# Start only Next.js
docker compose up -d workspace-nextjs

# Rebuild after Dockerfile changes
docker compose up -d --build

# View logs
docker compose logs -f workspace-python
docker compose logs -f workspace-nextjs
```

## Keeping Claude Running When You Disconnect

Use `tmux` inside code-server's terminal so Claude keeps working after you close the browser:

```bash
tmux new -s claude
claude remote-control --name "Python Workspace"
# Ctrl+B, D to detach — Claude keeps running

# Reattach later
tmux attach -t claude
```

## Notes

- SSH agent forwarding is configured automatically via `SSH_AUTH_SOCK` — any key loaded with `ssh-add` on the host is available inside both containers for git operations.
- The `~/.claude` directory is shared between both containers and the host, so skills and settings you create persist across rebuilds.
- Project-level Claude settings live in `python/settings.json` and `nextjs/settings.json` and are mounted at `/workspace/.claude/settings.json` inside each container.
