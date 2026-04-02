#!/usr/bin/env bash
set -euo pipefail

: "${CODEX_SANDBOX_NETWORK_ACCESS:=true}"

mkdir -p \
  "${CODEX_HOME}" \
  "${HOME}/.agents/skills" \
  "${HOME}/.agents/plugins" \
  "${CODEX_HOME}/plugins" \
  /workspace

if [ ! -f "${CODEX_HOME}/config.toml" ] && [ -f /opt/codex-bootstrap/config.toml ]; then
  sed "s/__CODEX_SANDBOX_NETWORK_ACCESS__/${CODEX_SANDBOX_NETWORK_ACCESS}/" \
    /opt/codex-bootstrap/config.toml > "${CODEX_HOME}/config.toml"
fi

if [ ! -f "${CODEX_HOME}/AGENTS.md" ] && [ -f /opt/codex-bootstrap/AGENTS.md ]; then
  cp /opt/codex-bootstrap/AGENTS.md "${CODEX_HOME}/AGENTS.md"
fi

exec "$@"
