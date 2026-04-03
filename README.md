# codex-docker

`codex-docker` is a public Docker stack for [Codex CLI](https://www.npmjs.com/package/@openai/codex), built for practical day-to-day use with strong host separation, reproducible tooling, and broad platform integration.

## Prerequisites

- [Docker Engine](https://docs.docker.com/engine/) with [Docker Compose plugin](https://docs.docker.com/compose/)
- Optional: [Task](https://taskfile.dev/)
- Network access for image pulls, package downloads, OAuth, and remote CLI operations
- Valid OpenAI authentication path (ChatGPT device login or API key)

## Included tools

- [Codex CLI](https://www.npmjs.com/package/@openai/codex)
- [oh-my-codex](https://www.npmjs.com/package/oh-my-codex)
- [GitHub CLI (`gh`)](https://cli.github.com/manual/)
- [GitLab CLI (`glab`)](https://docs.gitlab.com/cli/)
- [atlcli](https://atlcli.sh/)
- Language/toolchain from base image:
  - [Node.js](https://nodejs.org/)
  - [PHP](https://www.php.net/)
  - [Python](https://www.python.org/)
  - [Git](https://git-scm.com/)

## Security boundaries and limits

This stack is designed for strong host separation, not full sandbox isolation.

- The container runs non-root, drops Linux capabilities, and enables `no-new-privileges`.
- Runtime state is isolated in `./state/home`.
- Host identity/config mounts are excluded by default (`~/.codex`, `~/.agents`, `~/.ssh`, `~/.gitconfig`, Docker socket).
- `./workspace` is a host bind mount and is intentionally writable by container processes.
- Network is enabled by default (`CODEX_SANDBOX_NETWORK_ACCESS=true`).

> [!WARNING]
> Disabling network (`CODEX_SANDBOX_NETWORK_ACCESS=false`) breaks MCP/OAuth flows and most remote platform operations (`gh`, `glab`, `atlcli`, Linear MCP). Use only for offline/local-only workflows.

## Quick start

```bash
cp .env.example .env
task init-env
task build
task smoke
task omx-setup
./bin/codex-login-chatgpt
task codex
```

API key auth:

```bash
./bin/codex-login-api
```

## Task reference

| Task | Purpose | When to use |
|---|---|---|
| `task init-env` | Initialize `.env` and set `HOST_UID`/`HOST_GID` from current host user | First setup and after cloning on a different machine |
| `task config` | Render effective Compose config | Validate env/config resolution |
| `task build` | Build image | After Dockerfile or dependency changes |
| `task version` | Show Codex CLI version in container | Quick sanity check |
| `task smoke` | Full smoke suite (Codex/OMX/platform CLIs/skills) | Before first use, after updates |
| `task platform-smoke` | Validate platform CLIs and MCP command availability | Platform integration checks |
| `task skills-verify` | Verify all vendored skills are present in isolated home | Skill bundle integrity check |
| `task doctor` | Extended runtime checks (`smoke` + MCP list + OMX doctor) | Troubleshooting and release validation |
| `task omx-setup` | Interactive [oh-my-codex](https://www.npmjs.com/package/oh-my-codex) setup | First run |
| `task omx-doctor` | OMX diagnostics | Troubleshooting |
| `task mcp-list` | List configured MCP servers | MCP status check |
| `task linear-mcp-add` | Add official [Linear MCP](https://mcp.linear.app/mcp) endpoint and start OAuth on first run | First Linear setup |
| `task linear-mcp-login` | Retry Linear MCP OAuth | If auth did not complete |
| `task first-run` | Recommended bootstrap flow | Standard first-time workflow |
| `task codex` | Start interactive Codex | Main daily usage |
| `task exec -- "<prompt>"` | Non-interactive Codex execution | Scripted/one-shot runs |
| `task shell` | Open shell in container | Manual inspection/debugging |

Headless OAuth note:

- On headless systems, copy the printed authorization URL from `linear-mcp-add` and complete it in a browser manually.

## Configuration

### Build configuration (`docker compose build`)

- `CODEX_UNIVERSAL_IMAGE`
- `CODEX_VERSION`
- `OMX_VERSION`
- `GH_VERSION`
- `GLAB_VERSION`
- `ATLCLI_VERSION`

### Runtime configuration (`docker compose run`)

- `HOST_UID`, `HOST_GID`
- `CODEX_SANDBOX_NETWORK_ACCESS`
- `FORCE_SKILL_SYNC`
- `OPENAI_API_KEY`, `CODEX_API_KEY`
- `GH_TOKEN`, `GITHUB_TOKEN`
- `GLAB_TOKEN`, `GITLAB_TOKEN`
- `ATLCLI_API_TOKEN`, `ATLCLI_EMAIL`, `ATLCLI_SITE`, `ATLCLI_BASE_URL`

`FORCE_SKILL_SYNC=false` keeps user-modified skills in `state/home/.agents/skills` intact across restarts.  
Set `FORCE_SKILL_SYNC=true` to overwrite local skill copies from `bootstrap/skills` on startup.

### Secrets handling

- Do not commit `.env` files.
- Do not pass secrets directly on command lines when avoidable.
- Use least-privilege tokens for `gh`, `glab`, and `atlcli`.
- Prefer secret managers or CI secret stores in automated environments.

## Skills

`bootstrap/skills` is vendored in-repo and synced into `~/.agents/skills` in the isolated runtime home.

Included categories:

- platform skills (`github`, `glab`, `atlcli`, `linear`)
- Symfony and Doctrine skills
- testing, debugging, architecture, CI/CD, and security skills

## Repository layout

- `Dockerfile`
- `docker-compose.yml`
- `Taskfile.yml`
- `bootstrap/config.toml`
- `bootstrap/AGENTS.md`
- `bootstrap/skills/`
- `docker/entrypoint.sh`
- `bin/`
- `state/home/`
- `workspace/`
- `docs/archive/README.old.md`
