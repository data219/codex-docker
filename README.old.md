# codex-isolated-3

Consolidated Docker setup for Codex CLI focused on three goals:

- isolated state from the host
- universal language/tool coverage via `codex-universal`
- practical day-to-day UX with small wrapper scripts

## What this stack isolates

This setup does not mount:

- host `~/.codex`
- host `~/.agents`
- host `~/.ssh`
- host `~/.gitconfig`
- host Docker socket

The container gets its own persisted home under `./state/home` and its own project workspace under `./workspace`.

## Why this stack exists

`codex-isolated-1` had better UX but weaker hardening and limited tool coverage.
`codex-isolated-2` had a stronger security posture and a universal base image but rougher day-to-day ergonomics.

`codex-isolated-3` combines:

- `codex-universal` base image
- pinned `oh-my-codex` runtime helper
- pinned `gh`, `glab`, and `atlcli` platform CLIs
- first-run bootstrap of `config.toml` and `AGENTS.md`
- first-run bootstrap of the required platform skills and Symfony Superpowers skills
- wrapper scripts for common Codex actions
- non-root runtime user
- compose hardening with `no-new-privileges` and dropped Linux capabilities
- network enabled by default for effective Codex usage
- direct access to the toolchains shipped by the pinned base image
- Linear prepared through Codex MCP with `rmcp_client`

## Files

- `Dockerfile`
- `docker-compose.yml`
- `.env.example`
- `bootstrap/config.toml`
- `bootstrap/AGENTS.md`
- `docker/entrypoint.sh`
- `bin/`
- `state/home/`
- `workspace/`

## Quick start

```bash
cp .env.example .env
docker compose build
./bin/codex-login-chatgpt
./bin/codex
```

API-key login:

```bash
./bin/codex-login-api
```

Taskfile usage:

```bash
task build
task smoke
task platform-smoke
task omx-setup
task omx-doctor
task linear-mcp-add
task linear-mcp-login
task login-chatgpt
task codex
task exec -- "review this repository and summarize risky areas"
```

If `task` is not installed on your host yet:

```bash
sudo snap install task --classic
# or
brew install go-task/tap/go-task
```

Open a shell inside the isolated container:

```bash
./bin/codex-shell
```

Run a one-off non-interactive prompt:

```bash
./bin/codex-exec "review this repository and summarize risky areas"
```

## Notes

- `CODEX_SANDBOX_NETWORK_ACCESS=true` is the default because Codex is much less useful without network access.
- If you want a stricter runtime, set `CODEX_SANDBOX_NETWORK_ACCESS=false` before first start or edit `state/home/.codex/config.toml` later.
- The persisted home also stores isolated auth, config, and `.agents` assets.
- `oh-my-codex` is preinstalled; run `task omx-setup` once if you want its workflow layer initialized in the persisted home.
- `gh`, `glab`, and `atlcli` are preinstalled and pinned in the image.
- `linear` is intentionally integrated through the official Linear MCP endpoint instead of an unofficial standalone CLI.
- On every container start, the vendored `github`, `glab`, `atlcli`, `linear`, and Symfony skill directories are synced into the isolated `~/.agents/skills`.

## Bundled skills

This stack ships with:

- platform skills: `github`, `glab`, `atlcli`, `linear`
- all Symfony Superpowers skills from the normal `~/.agents/skills` set, including `using-symfony-superpowers`, `symfony-messenger`, `symfony-cache`, `symfony-voters`, Doctrine, testing, and architecture helpers

The bundled skills live in the stack repository and are copied into the isolated home during container startup.

## Platform integration

Available CLIs inside the container:

- `gh`
- `glab`
- `atlcli`
- `codex` with Linear MCP support enabled

Recommended Linear setup:

```bash
task linear-mcp-add
task linear-mcp-login
task mcp-list
```

`linear-mcp-add` is idempotent. On the first run it both adds the server config and starts the Linear OAuth flow.
If the server is already configured and you only need to retry auth, use `task linear-mcp-login`.

## First run with oh-my-codex

Recommended first-run sequence:

```bash
task first-run
```

What this does:

- `task smoke` confirms the container, Codex CLI, and toolchain paths are healthy.
- `task platform-smoke` is included in `task smoke` and validates `gh`, `glab`, `atlcli`, Linear MCP support, and the vendored skill payload.
- `task omx-setup` runs the interactive OMX bootstrap and writes user-level OMX state into `./state/home`.
- `task omx-doctor` validates the OMX installation and reports actionable diagnostics.
- `task codex` starts your regular Codex workflow with OMX available.

If setup was interrupted:

- run `task omx-setup` again
- then run `task omx-doctor`
- run `task linear-mcp-add` when you are ready to connect Linear for the first time
- run `task linear-mcp-login` if the Linear MCP server already exists and you only need to retry OAuth
