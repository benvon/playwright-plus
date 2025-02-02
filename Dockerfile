FROM mcr.microsoft.com/playwright:v1.50.1-noble

RUN apt-get update && \
  apt-get install --no-install-recommends -y \
    jq=1.7.1-3build1 \
    && \
  rm -rf /var/lib/apt/lists/* 

RUN npm install -g corepack@0.24.1 && \
    corepack enable pnpm && \
    corepack enable yarn
    
COPY package.json /tmp/package.json

WORKDIR /tmp

# hadolint ignore=DL3016
RUN npm install -g $(jq -r '.dependencies | to_entries | map(.key + "@" + .value) | join(" ")' package.json)

RUN rm package.json

