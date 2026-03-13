# aman

Note: this whole thing is vide coded and unchecked, don’t use it.

A CLI tool to run Claude Code in isolated Docker containers via Colima, one VM per project.

## Setup

- Run setup.sh to install `colima` and `docker`, and copy agent configs into `var`:
  - `~/.claude.json`
  - `~/.claude/*~`
  - `~/.copilot/*`
  - `~/.gemini/*`

## Files

- `aman` — the CLI script (bash)
- `Dockerfile` — Docker image definition for the agent CLIs
- `var/` — shared Claude state directory
  - `.claude.json` — Claude settings (mapped to `~/.claude.json` in container)
  - `.claude/` — Claude data directory (mapped to `~/.claude/` in container)
  - `agent-image.tar` — shared exported Docker image archive

## Architecture

Each project gets its own named Colima profile (a separate Lima VM), derived from the
project's absolute path. This provides filesystem isolation: the VM only mounts the
project directory, nothing else.

The project directory is mounted with macOS paths translated to Linux paths (e.g.,
`/Users/yuan/myproject` → `/home/myproject`).

### Shared State

All containers share the same Claude configuration files via the `var/` directory:
- `var/.claude.json` → `~/.claude.json`
- `var/.claude/` → `~/.claude/`

This means all Claude sessions across all containers share settings, history, and cached data.

The path translation (`$HOME/` → `/home/`) ensures consistent Linux paths in
Claude's project-specific state stored in `~/.claude/`.

Profile naming: `am-<path>` where `<path>` is the absolute project path with `/`
replaced by `-` and the leading `/` stripped. Example:
`/Users/yuan/projects/foo` → `am-Users-yuan-projects-foo`

Each project still gets its own Colima profile for filesystem isolation.

The Docker image (`agent-image`) is stored as a shared archive in `var/`.
If `var/agent-image.tar` does not exist, `aman` builds it and stores it there.
Before each container run, `aman` reloads that archive into the active Colima profile.
Each CLI session still starts a fresh disposable container.

## Commands
```
aman start [project-dir]        # Start Claude Code for a project (default: cwd)
aman list                       # List all aman Colima instances
aman clean [project-dir]        # Remove colima and docker instance for a project
aman clean-image [project-dir]  # Remove the shared image archive
```

## Dependencies

- `colima` — container runtime / VM manager
- `docker` — CLI only, no Docker Desktop
- `node:22-slim` base image
- macOS keychain entries for API keys

## Setup

1. Install dependencies:
```bash
   brew install colima docker
```

2. Add API keys to the macOS keychain:
```bash
   security add-generic-password -s "anthropic-api-key" -a "$USER" -w
   security add-generic-password -s "gemini-api-key" -a "$USER" -w
   security add-generic-password -s "copilot-api-key" -a "$USER" -w
```

3. Install the script:
```bash
   cp aman ~/bin/aman
   chmod +x ~/bin/aman
```

or use a soft link:

```bash
ln -s "$(pwd)/aman" ~/bin/aman
```

## Key Constants (in `aman`)

| Variable         | Value                        | Purpose                            |
|------------------|------------------------------|------------------------------------|
| Profile prefix   | `am-`                        | Identifies aman-managed profiles   |
| Colima CPU       | 1                            | vCPUs per VM                       |
| Colima memory    | 1                            | GB RAM per VM                      |
| Mount type       | `virtiofs`                   | Fast file sync (requires macOS 12+)|

## Known Limitations

- Path-to-profile-name conversion replaces both `/` and `-` with `-`, so paths
  containing dashes are ambiguous when reversing (e.g. in `aman list`). If this
  is a problem, consider storing a path→profile map in `~/.config/claude-code/`.
- If you change the Docker image inputs, remove `var/agent-image.tar` or run
  `aman clean-image` so the shared archive is rebuilt on the next run.
- `--mount-type virtiofs` requires macOS 12+.

## Security Model

- The Colima VM only mounts the project directory — not the home directory.
- API keys are retrieved from the macOS keychain at runtime and passed
  as environment variables into the container.
- Claude Code runs with `--dangerously-skip-permissions` (yolo mode). Use git so
  you can roll back changes.
- The container has outbound network access (required for the Anthropic API). It is
  not egress-filtered beyond what macOS/Colima provides.
