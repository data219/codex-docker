# codex-isolated-3

A consolidated Docker stack for Codex CLI that combines isolation, broad tool coverage, platform integrations, and the smoother day-to-day UX of the three variants.

`codex-isolated-3` is the recommended default. It keeps the same hardening baseline as `codex-isolated-2`, but is framed as the main working environment for daily Codex + OMX use.

> [!TIP]
> If you only want one stack to keep using, start here. `codex-isolated-3` is the practical default for regular Codex work, while `codex-isolated-2` remains the stricter sibling.

## What this stack gives you

- Isolated Codex home under `./state/home`
- Pinned `codex-universal` base image by digest
- Non-root runtime with host UID/GID mapping
- Hardened Compose settings with `cap_drop: ALL` and `no-new-privileges`
- Preinstalled `codex`, `omx`, `gh`, `glab`, and `atlcli`
- Official Linear MCP workflow available inside the container
- Vendored platform, Symfony, engineering, CI/CD, and security skills
- Small wrapper scripts and task targets for fast daily use

## Isolation model

This stack does not mount:

- host `~/.codex`
- host `~/.agents`
- host `~/.ssh`
- host `~/.gitconfig`
- host Docker socket

Everything relevant to the Codex runtime stays local to this stack:

- auth and config
- OMX setup state
- MCP server config
- vendored skills under the isolated `~/.agents/skills`

## Included tooling

The container includes:

- Codex CLI and `oh-my-codex`
- Node.js, PHP, Python, and Git from the universal base image
- GitHub CLI: `gh`
- GitLab CLI: `glab`
- Atlassian CLI: `atlcli`
- Linear through the official MCP endpoint

The vendored skill bundle includes:

- `github`, `glab`, `atlcli`, `linear`
- Symfony, Doctrine, and testing skills
- debugging, architecture, CI/CD, and security skills from your normal setup

## Quick start

```bash
cp .env.example .env
task build
task smoke
task omx-setup
./bin/codex-login-chatgpt
task codex
```

For API-key auth:

```bash
./bin/codex-login-api
```

If `task` is not installed yet:

```bash
sudo snap install task --classic
# or
brew install go-task/tap/go-task
```

## Daily commands

```bash
task build
task smoke
task codex
task exec -- "review this repository and summarize risky areas"
task shell
```

Additional helper tasks:

```bash
task platform-smoke
task omx-doctor
task mcp-list
task linear-mcp-add
task linear-mcp-login
```

## First run

Use the standard bootstrap flow:

```bash
task first-run
```

That flow:

- validates the image and toolchain
- checks the platform CLIs and vendored skill sync
- initializes `oh-my-codex`
- starts Codex in the prepared environment

When you want Linear available in the isolated setup:

```bash
task linear-mcp-add
task mcp-list
```

`linear-mcp-add` is idempotent. On the first run it adds the MCP server and starts the OAuth flow.

## Configuration

The default runtime favors usability:

- `CODEX_SANDBOX_NETWORK_ACCESS=true`
- persistent isolated home in `./state/home`
- workspace mounted at `./workspace`

If you want a stricter runtime, override the network setting in `.env`:

```bash
CODEX_SANDBOX_NETWORK_ACCESS=false
```

## Layout

- `Dockerfile`: pinned runtime image and CLI installation
- `docker-compose.yml`: hardened service definition
- `Taskfile.yml`: build, smoke, OMX, and MCP workflows
- `bootstrap/`: default Codex config, AGENTS, and vendored skills
- `bin/`: wrappers for Codex entry points
- `state/home/`: isolated persisted runtime state
- `workspace/`: mounted working directory

## Why keep `codex-isolated-2` as well

`codex-isolated-3` is the default working stack.

Keep `codex-isolated-2` if you want:

- a stricter baseline as your mental model
- a second maintained stack for comparison
- a conservative fallback without changing your main daily environment
