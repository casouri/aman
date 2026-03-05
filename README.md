# aman

Note: this whole thing is vide coded and unchecked, don’t use it.

A CLI tool to run Claude Code in isolated Docker containers via Colima, one VM per project.

## Setup

- Copy configs into `var/.claude.json` and `var/.claude/settings.json`.
- Fix the `SRC_DIR` in `aman`.

## Files

- `aman` — the CLI script (bash)
- `Dockerfile` — Docker image definition for Claude Code
- `var/` — shared Claude state directory
  - `.claude.json` — Claude settings (mapped to `~/.claude.json` in container)
  - `.claude/` — Claude data directory (mapped to `~/.claude/` in container)

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

The Docker image (`claude-code`) is built once per Colima profile and reused on
subsequent runs.

## Commands
```
aman start [project-dir]        # Start Claude Code for a project (default: cwd)
aman list                       # List all aman Colima instances
aman clean [project-dir]        # Remove colima and docker instance for a project
aman clean-image [project-dir]  # Remove the claude-code docker image for a project
```

## Dependencies

- `colima` — container runtime / VM manager
- `docker` — CLI only, no Docker Desktop
- `node:22-slim` base image
- macOS keychain entry for the Anthropic API key

## Setup

1. Install dependencies:
```bash
   brew install colima docker
```

2. Update `SRC_DIR` to point to `Dockerfile`

3. Add the Anthropic API key to the macOS keychain:
```bash
   security add-generic-password -s "anthropic-api-key" -a "$USER" -w
```

4. Install the script:
```bash
   cp aman /usr/local/bin/aman
   chmod +x /usr/local/bin/aman
```

or use a soft link:

```bash
ln -s "$(pwd)/aman" /usr/local/bin/aman
```

## Key Constants (in `aman`)

| Variable         | Value                        | Purpose                            |
|------------------|------------------------------|------------------------------------|
| `SRC_DIR`        | `$HOME/p/claudecode`         | Location of the Dockerfile & script|
| Profile prefix   | `am-`                        | Identifies aman-managed profiles|
| Colima CPU       | 1                            | vCPUs per VM                     |
| Colima memory    | 1                            | GB RAM per VM                    |
| Mount type       | `virtiofs`                   | Fast file sync (requires macOS 12+)|

## Known Limitations

- Path-to-profile-name conversion replaces both `/` and `-` with `-`, so paths
  containing dashes are ambiguous when reversing (e.g. in `aman list`). If this
  is a problem, consider storing a path→profile map in `~/.config/claude-code/`.
- Images are not shared across Colima profiles. Each VM builds its own `claude-code`
  image on first run.
- `aman list` only shows the Colima status columns; it does not show running Docker
  containers within each VM.
- `--mount-type virtiofs` requires macOS 12+.

## Security Model

- The Colima VM only mounts the project directory — not the home directory.
- The Anthropic API key is retrieved from the macOS keychain at runtime and passed
  as an environment variable into the container.
- Claude Code runs with `--dangerously-skip-permissions` (yolo mode). Use git so
  you can roll back changes.
- The container has outbound network access (required for the Anthropic API). It is
  not egress-filtered beyond what macOS/Colima provides.
