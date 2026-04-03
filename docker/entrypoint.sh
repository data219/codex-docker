#!/usr/bin/env bash
set -euo pipefail

: "${CODEX_SANDBOX_NETWORK_ACCESS:=true}"
: "${FORCE_SKILL_SYNC:=false}"

mkdir -p \
  "${CODEX_HOME}" \
  "${HOME}/.agents/skills" \
  "${HOME}/.agents/plugins" \
  "${HOME}/.config/gh" \
  "${HOME}/.config/glab" \
  "${CODEX_HOME}/plugins" \
  /workspace

if [ ! -f "${CODEX_HOME}/config.toml" ] && [ -f /opt/codex-bootstrap/config.toml ]; then
  sed "s/__CODEX_SANDBOX_NETWORK_ACCESS__/${CODEX_SANDBOX_NETWORK_ACCESS}/" \
    /opt/codex-bootstrap/config.toml > "${CODEX_HOME}/config.toml"
fi

if [ -f "${CODEX_HOME}/config.toml" ] && ! grep -q '^[[:space:]]*rmcp_client[[:space:]]*=' "${CODEX_HOME}/config.toml"; then
  if grep -q '^\[features\]$' "${CODEX_HOME}/config.toml"; then
    tmp_config="$(mktemp)"
    awk '
      { print }
      !done && $0 == "[features]" { print "rmcp_client = true"; done = 1 }
    ' "${CODEX_HOME}/config.toml" > "${tmp_config}"
    mv "${tmp_config}" "${CODEX_HOME}/config.toml"
  else
    printf '\n[features]\nrmcp_client = true\n' >> "${CODEX_HOME}/config.toml"
  fi
fi

if [ ! -f "${CODEX_HOME}/AGENTS.md" ] && [ -f /opt/codex-bootstrap/AGENTS.md ]; then
  cp /opt/codex-bootstrap/AGENTS.md "${CODEX_HOME}/AGENTS.md"
fi

if [ -d /opt/codex-bootstrap/skills ]; then
  for skill_dir in /opt/codex-bootstrap/skills/*; do
    [ -d "${skill_dir}" ] || continue
    skill_name="$(basename "${skill_dir}")"
    target_dir="${HOME}/.agents/skills/${skill_name}"
    if [ "${FORCE_SKILL_SYNC}" = "true" ] || [ ! -d "${target_dir}" ]; then
      rm -rf "${target_dir}"
      cp -a "${skill_dir}" "${target_dir}"
    fi
  done
fi

exec "$@"
