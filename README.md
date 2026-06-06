# claude-remote

Ansible-managed dev environment on TrueNAS SCALE. A single playbook, run from a Mac, provisions a ZFS dataset, installs Claude Code on the TrueNAS host, and renders Docker Compose dev containers (browser-accessible VS Code via code-server) for each project. Everything is idempotent — re-running the playbook brings the host back to the desired state.

---

## Architecture

```
Mac (you run Ansible here)
  └─ ansible-playbook → SSH → TrueNAS SCALE host
                                │
                                ├─ ZFS dataset: /mnt/applications/claude-remote/
                                │    ├─ claude/          ← claude user home, SSH keys
                                │    ├─ claude-config/   ← ~/.claude (credentials, settings)
                                │    ├─ runtime/         ← Node.js, Claude Code binary, jq
                                │    └─ repositories/    ← git submodules (one per project)
                                │
                                ├─ Host: claude user runs `claude` in tmux (one session/project)
                                │
                                └─ Docker dev containers (code-server browser IDE)
                                     devcontainer-all        → port 8080 (all repos)
                                     devcontainer-<project>  → port 808x (one repo each)
                                          └─ project's own docker-compose (app stack)
```

---

## Prerequisites

- TrueNAS SCALE 24.10+ (Electric Eel) with native Docker enabled
- Ansible 2.15+ installed on your Mac (`brew install ansible`)
- SSH key pair — public key will be pasted into TrueNAS UI during user creation
- The `claude` user created manually in the TrueNAS UI (see next section)

---

## Creating the `claude` User on TrueNAS

These steps are done once in the TrueNAS web UI before running the playbook.

### 1. Create the ZFS Dataset

- Go to **Storage → Create Pool** (or use an existing pool)
- Add a dataset: path `applications/claude-remote` at the pool root
- Leave default settings (inherits compression, etc.)

### 2. Create the User

- Go to **Credentials → Local Users → Add**
- Fill in:
  - **Username:** `claude`
  - **Full Name:** `Claude`
  - **Home Directory:** `/mnt/applications/claude-remote/claude`
  - Check **Create Home Directory**
  - **Shell:** `zsh`
  - **Disable Password:** yes (SSH key only)
  - **Authorized Keys:** paste your SSH public key (`~/.ssh/id_ed25519.pub` or equivalent)
- Under **Auxiliary Groups**, add the group that has access to the Docker socket (typically `docker`)
- Save

### 3. Grant Passwordless Sudo

- Go to **System → Shell** (or SSH in as admin) and run:
  ```bash
  echo 'claude ALL=(ALL) NOPASSWD: ALL' > /usr/local/etc/sudoers.d/claude
  ```

### 4. Enable SSH Service

- Go to **System → Services → SSH** and ensure it is running and set to start automatically

---

## First-Time Setup

```bash
# 1. Set your TrueNAS IP in the inventory
#    Edit ansible/inventory.ini — replace TRUENAS_IP with the real address
vim ansible/inventory.ini

# 3. Set your project list and pool path
#    Edit ansible/group_vars/all.yml:
#      - pool_path (default /mnt/applications/claude-remote is usually correct)
#      - master_repo_url (your actual Git remote for this repo)
#      - projects list (name + port for each submodule)
vim ansible/group_vars/all.yml

# 4. Run the playbook
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

The playbook runs these roles in order:

| Role | What it does |
|---|---|
| `dataset` | Creates subdirectory layout under the ZFS dataset |
| `runtime` | Installs Node.js, Claude Code, and jq into `runtime/` |
| `host_shell` | Installs zsh, oh-my-zsh, configures `.zshrc` for the `claude` user |
| `claude_config` | Deploys `settings.json` and `statusline.sh`, creates `~/.claude` symlink |
| `repos` | Clones this master repo and all submodules into `repositories/` on the host |
| `devcontainers` | Renders `docker-compose.yml` from the Jinja2 template, creates `.env` if missing |

---

## First Claude Login

After the playbook completes, SSH into TrueNAS as the `claude` user and run `claude` once to complete OAuth:

```bash
ssh claude@<TRUENAS_IP>
claude   # follow the browser OAuth prompt; credentials are saved to the dataset
```

Credentials are stored in `/mnt/applications/claude-remote/claude-config/` and persist across host reboots and playbook re-runs.

---

## Daily Usage

### Running Claude on the Host

Each project gets its own tmux session so Claude can keep working after you disconnect:

```bash
ssh claude@<TRUENAS_IP>

# Start a session for a project
tmux new -s xml-pdf
cd /mnt/applications/claude-remote/repositories/xml-pdf
claude
# Ctrl+B, D  ← detach

# Reattach later
tmux attach -t xml-pdf
```

### Starting Dev Containers (browser IDE)

Dev containers are managed by the rendered `docker-compose.yml` in the dataset root:

```bash
ssh claude@<TRUENAS_IP>
cd /mnt/applications/claude-remote

# Start the aggregate container (all repos, port 8080)
docker compose --profile all up -d

# Start only one project's container (e.g., xml-pdf on port 8081)
docker compose --profile xml-pdf up -d

# Stop everything
docker compose down
```

Open the browser IDE at `http://<TRUENAS_IP>:<PORT>` and authenticate with the password stored in `.env`.

### Starting a Project's App Stack

Each project repository contains its own `docker-compose.yml` for its application services. Run it from inside the repository:

```bash
cd /mnt/applications/claude-remote/repositories/xml-pdf
docker compose up -d
```

---

## Adding a Project

1. Add the project as a git submodule (on your Mac):
   ```bash
   git submodule add git@github.com:YOUR_USER/<project>.git repositories/<project>
   git commit -m "add <project> submodule"
   git push
   ```

2. Add the project to `ansible/group_vars/all.yml` under `projects:`:
   ```yaml
   projects:
     - name: xml-pdf
       port: 8081
     - name: <project>      # ← add this
       port: 8082
   ```

3. Re-run the playbook:
   ```bash
   ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
   ```

The playbook will clone the new submodule on the host and re-render `docker-compose.yml` with the new container.

---

## Recovery

If anything breaks on the host, just re-run the playbook — all roles are idempotent:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

Data in the ZFS dataset (credentials, repositories, config) is never deleted by the playbook.
