# syntax=docker/dockerfile:1.7
#
# Hermes Agent on Render, pre-baked with Render tooling.
# Modified for free plan + GitHub backup of self-improvement data
# + custom identity: Messenger of the Digital (eras')
#
ARG HERMES_IMAGE=docker.io/nousresearch/hermes-agent:v2026.5.7
FROM ${HERMES_IMAGE}

USER root
RUN chown -R hermes:hermes /opt/hermes/ui-tui /opt/hermes/node_modules \
 && mkdir -p /opt/hermes/ui-tui/packages/hermes-ink/dist /opt/hermes/ui-tui/dist \
 && touch /opt/hermes/ui-tui/packages/hermes-ink/dist/ink-bundle.js \
          /opt/hermes/ui-tui/dist/entry.js \
 && chown -R hermes:hermes /opt/hermes/ui-tui

ARG RENDER_SKILLS_REPO=render-oss/skills
ARG RENDER_SKILLS_REF=1b8496570748203351f628b2ae738805ac2c23d5
RUN set -eu; \
    tmp="$(mktemp -d)"; \
    url="https://codeload.github.com/${RENDER_SKILLS_REPO}/tar.gz/${RENDER_SKILLS_REF}"; \
    curl -fsSL --retry 3 -o "${tmp}/skills.tar.gz" "${url}"; \
    tar -xzf "${tmp}/skills.tar.gz" -C "${tmp}"; \
    extracted="$(find "${tmp}" -maxdepth 2 -type d -name 'skills' | head -n 1)"; \
    test -n "${extracted}" || { echo "could not find skills/ in tarball" >&2; exit 1; }; \
    install -d -o hermes -g hermes -m 0755 /opt/render-tools/skills-upstream; \
    cp -a "${extracted}/." /opt/render-tools/skills-upstream/; \
    chown -R hermes:hermes /opt/render-tools/skills-upstream; \
    rm -rf "${tmp}"; \
    echo "${RENDER_SKILLS_REPO}@${RENDER_SKILLS_REF}" > /opt/render-tools/skills-upstream/.source

COPY --chown=hermes:hermes skills/ /opt/render-tools/skills-local/

# Copy all our scripts
COPY --chown=root:root scripts/bootstrap.sh /opt/render-tools/bootstrap.sh
COPY --chown=root:root scripts/patch-config.py /opt/render-tools/patch-config.py
COPY --chown=root:root scripts/backup-to-github.sh /opt/render-tools/backup-to-github.sh
COPY --chown=root:root scripts/restore-from-github.sh /opt/render-tools/restore-from-github.sh
COPY --chown=root:root scripts/start-backup-loop.sh /opt/render-tools/start-backup-loop.sh
COPY --chown=root:root scripts/seed-soul.sh /opt/render-tools/seed-soul.sh

RUN chmod 0755 /opt/render-tools/bootstrap.sh \
               /opt/render-tools/patch-config.py \
               /opt/render-tools/backup-to-github.sh \
               /opt/render-tools/restore-from-github.sh \
               /opt/render-tools/start-backup-loop.sh \
               /opt/render-tools/seed-soul.sh

# Install git (needed for the backup/restore scripts)
RUN apt-get update && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

RUN install -d -o hermes -g hermes -m 0755 /opt/data

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/opt/render-tools/bootstrap.sh"]
CMD ["gateway", "run"]
