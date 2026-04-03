ARG CODEX_UNIVERSAL_IMAGE=ghcr.io/openai/codex-universal:latest@sha256:956c2e7dd1590fc12763f172579d777464312006b9fa1f6405f5f1b78b8ea2dc
FROM ${CODEX_UNIVERSAL_IMAGE}

USER root

ARG HOST_UID=1000
ARG HOST_GID=1000
ARG CODEX_VERSION=0.118.0
ARG OMX_VERSION=0.11.12
ARG GH_VERSION=2.89.0
ARG GLAB_VERSION=1.91.0
ARG ATLCLI_VERSION=0.15.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl tar gzip \
    && rm -rf /var/lib/apt/lists/*

RUN . /root/.nvm/nvm.sh \
    && npm install -g @openai/codex@${CODEX_VERSION} oh-my-codex@${OMX_VERSION} \
    && ln -sf "$(command -v node)" /usr/local/bin/node \
    && ln -sf "$(npm prefix -g)/bin/codex" /usr/local/bin/codex \
    && ln -sf "$(npm prefix -g)/bin/omx" /usr/local/bin/omx

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "${arch}" in \
      amd64) gh_arch="amd64"; glab_arch="amd64"; atlcli_arch="x64" ;; \
      arm64) gh_arch="arm64"; glab_arch="arm64"; atlcli_arch="arm64" ;; \
      *) echo "unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    gh_archive="gh_${GH_VERSION}_linux_${gh_arch}.tar.gz"; \
    glab_archive="glab_${GLAB_VERSION}_linux_${glab_arch}.tar.gz"; \
    atlcli_archive="atlcli-linux-${atlcli_arch}.tar.gz"; \
    install_archive() { \
      binary="$1"; \
      url="$2"; \
      checksum_url="$3"; \
      archive_name="$4"; \
      tmpdir="$(mktemp -d)"; \
      mkdir -p "${tmpdir}/unpack"; \
      curl -fsSL "${url}" -o "${tmpdir}/pkg.tgz"; \
      curl -fsSL "${checksum_url}" -o "${tmpdir}/checksums.txt"; \
      (cd "${tmpdir}" && awk -v target="${archive_name}" '$2 == target { print $1 "  " "pkg.tgz" }' checksums.txt | sha256sum -c -); \
      tar -xzf "${tmpdir}/pkg.tgz" -C "${tmpdir}/unpack"; \
      install -m 0755 "$(find "${tmpdir}/unpack" -type f -name "${binary}" | head -n 1)" "/usr/local/bin/${binary}"; \
      rm -rf "${tmpdir}"; \
    }; \
    install_archive gh "https://github.com/cli/cli/releases/download/v${GH_VERSION}/${gh_archive}" "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_checksums.txt" "${gh_archive}"; \
    install_archive glab "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/${glab_archive}" "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION}/checksums.txt" "${glab_archive}"; \
    install_archive atlcli "https://github.com/BjoernSchotte/atlcli/releases/download/v${ATLCLI_VERSION}/${atlcli_archive}" "https://github.com/BjoernSchotte/atlcli/releases/download/v${ATLCLI_VERSION}/checksums.txt" "${atlcli_archive}"

RUN set -eux; \
    chmod 755 /root; \
    sed -i '28,$d' /etc/profile; \
    printf '%s\n' \
      'eval "$(mise activate bash)"' \
      'export PYENV_ROOT="$HOME/.pyenv"' \
      'export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"' \
      'command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init - bash)"' \
      '[ -r "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' \
      '[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"' \
      'command -v phpenv >/dev/null 2>&1 && eval "$(phpenv init - bash)"' \
      >> /etc/profile; \
    if ! getent group "${HOST_GID}" >/dev/null; then \
        groupadd --gid "${HOST_GID}" codex-host; \
    fi; \
    if id -u codex >/dev/null 2>&1; then \
        usermod --non-unique --uid "${HOST_UID}" --gid "${HOST_GID}" --home /home/codex codex; \
    else \
        useradd --create-home --non-unique --uid "${HOST_UID}" --gid "${HOST_GID}" --shell /bin/bash codex; \
    fi; \
    mkdir -p /home/codex/.codex /home/codex/.agents/skills /home/codex/.agents/plugins /home/codex/.config/gh /home/codex/.config/glab /workspace /opt/codex-bootstrap; \
    chown -R "${HOST_UID}:${HOST_GID}" /home/codex /workspace /opt/codex-bootstrap

COPY --chown=codex:codex bootstrap/config.toml /opt/codex-bootstrap/config.toml
COPY --chown=codex:codex bootstrap/AGENTS.md /opt/codex-bootstrap/AGENTS.md
COPY --chown=codex:codex bootstrap/skills /opt/codex-bootstrap/skills
COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh

ENV HOME=/home/codex
ENV CODEX_HOME=/home/codex/.codex
WORKDIR /workspace

USER codex

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["codex"]
