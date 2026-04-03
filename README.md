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

### Runtime configuration (`docker compose run`)

#### Core runtime variables

| Variable | Default | Optional | What it configures |
|---|---|---|---|
| `HOST_UID` | `1000` | Yes (recommended to set) | Container user ID mapping for file ownership in mounted `./workspace` and `./state/home`. Use `task init-env` to set host-specific values. |
| `HOST_GID` | `1000` | Yes (recommended to set) | Container group ID mapping for writable host-mounted files. |
| `CODEX_SANDBOX_NETWORK_ACCESS` | `true` | Yes | Enables/disables outbound network access for Codex runtime operations. Set to `false` for offline/local-only runs. |
| `FORCE_SKILL_SYNC` | `false` | Yes | Controls skill sync behavior on startup. `false` preserves local edits in `state/home/.agents/skills`; `true` overwrites with `bootstrap/skills`. |

#### Tool and authentication variables

| Variable | Default | Optional | What it configures |
|---|---|---|---|
| `OPENAI_API_KEY` | empty | Yes | API-key auth for Codex CLI. Alternative to `codex login --device-auth`. |
| `CODEX_API_KEY` | empty | Yes | Alternative API-key variable for Codex CLI auth. |
| `GH_TOKEN` | empty | Yes | Token-based auth for `gh`. Not required if you use interactive `gh auth login`. |
| `GITHUB_TOKEN` | empty | Yes | Alternate GitHub token variable used by `gh` and automation contexts. |
| `GLAB_TOKEN` | empty | Yes | Token-based auth for `glab`. Not required if you use interactive `glab auth login`. |
| `GITLAB_TOKEN` | empty | Yes | Alternate GitLab token variable for `glab` and scripts. |
| `ATLCLI_API_TOKEN` | empty | Yes | Token auth for `atlcli` profile setup/non-interactive workflows. |
| `ATLCLI_EMAIL` | empty | Yes | Default Atlassian account email for `atlcli` auth flows. |
| `ATLCLI_SITE` | empty | Yes | Default Atlassian cloud site (for example `example.atlassian.net`) for `atlcli`. |
| `ATLCLI_BASE_URL` | empty | Yes | Base URL override for self-hosted/data-center Atlassian endpoints in `atlcli`. |

All tool auth env vars are optional. Interactive login flows remain supported for `codex`, `gh`, `glab`, and `atlcli`.

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
