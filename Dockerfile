FROM mcr.microsoft.com/playwright:v1.50.1-noble

RUN npm install -g corepack@0.24.1 && \
    corepack enable pnpm && \
    corepack enable yarn
    

COPY package.json /tmp/package.json

RUN cd /tmp && \
    npm install -g $(node -p "Object.entries(require('./package.json').dependencies).map(([pkg, ver]) => pkg + '@' + ver).join(' ')")

RUN rm /tmp/package.json

