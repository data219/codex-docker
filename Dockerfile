ARG CODEX_UNIVERSAL_IMAGE=ghcr.io/openai/codex-universal:latest@sha256:956c2e7dd1590fc12763f172579d777464312006b9fa1f6405f5f1b78b8ea2dc
FROM ${CODEX_UNIVERSAL_IMAGE}

USER root

ARG HOST_UID=1000
ARG HOST_GID=1000
ARG CODEX_VERSION=0.118.0
ARG OMX_VERSION=0.11.12

RUN . /root/.nvm/nvm.sh \
    && npm install -g @openai/codex@${CODEX_VERSION} oh-my-codex@${OMX_VERSION} \
    && ln -sf "$(command -v node)" /usr/local/bin/node \
    && ln -sf "$(npm prefix -g)/bin/codex" /usr/local/bin/codex \
    && ln -sf "$(npm prefix -g)/bin/omx" /usr/local/bin/omx

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
    mkdir -p /home/codex/.codex /home/codex/.agents/skills /home/codex/.agents/plugins /workspace /opt/codex-bootstrap; \
    chown -R "${HOST_UID}:${HOST_GID}" /home/codex /workspace /opt/codex-bootstrap

COPY --chown=codex:codex bootstrap/config.toml /opt/codex-bootstrap/config.toml
COPY --chown=codex:codex bootstrap/AGENTS.md /opt/codex-bootstrap/AGENTS.md
COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh

ENV HOME=/home/codex
ENV CODEX_HOME=/home/codex/.codex
WORKDIR /workspace

USER codex

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["codex"]
