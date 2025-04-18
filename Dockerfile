ARG PLAYWRIGHT_VERSION
FROM mcr.microsoft.com/playwright:v${PLAYWRIGHT_VERSION}-noble

ARG DEBIAN_FRONTEND=noninteractive
ARG AZURE_CLI_VERSION=2.70.0-1

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update && \
  apt-get install --no-install-recommends -y \
    apt-transport-https=2.7.14build2 \
    ca-certificates=20240203 \
    curl=8.5.0-2ubuntu10.6 \
    default-jdk \
    gnupg=2.4.4-2ubuntu17.2 \
    gpgconf=2.4.4-2ubuntu17.2 \
    gpgsm=2.4.4-2ubuntu17.2 \
    jq=1.7.1-3build1 \
    keyboxd=2.4.4-2ubuntu17.2 \
    lsb-release=12.0-2 \
    && \
  # Install Azure CLI
  curl --proto "=https" --tlsv1.2 -sSf -L https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null && \
  chmod go+r /etc/apt/keyrings/microsoft.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    azure-cli=${AZURE_CLI_VERSION}~noble \
  && \
  rm -rf /var/lib/apt/lists/* && \
  npm install -g corepack@0.24.1 && \
    corepack enable pnpm && \
    corepack enable yarn 

COPY package.json /ms-playwright-agent/package.json

WORKDIR /ms-playwright-agent

# hadolint ignore=DL3016,SC2046
RUN npm install -g $(jq -r '.dependencies | to_entries | map(.key + "@" + .value) | join(" ")' package.json) && \
  rm package.json

# The ADO agent does not support non-root users
# USER pwuser
