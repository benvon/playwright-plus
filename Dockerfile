FROM mcr.microsoft.com/playwright:v1.50.1-noble

RUN npm install -g corepack@0.24.1 && \
    corepack enable pnpm && \
    corepack enable yarn
    
RUN npm install -g \
    jest@29.7.0 \
    mocha@10.3.0 \
    chai@5.1.0 \
    ts-node@10.9.2 \
    eslint@8.57.0 \
    prettier@3.2.5 \
    @typescript-eslint/parser@7.1.1 \
    @typescript-eslint/eslint-plugin@7.1.1 \
    @types/jest@29.5.12 \
    @types/mocha@10.0.6 \
    @types/chai@4.3.12 \
    source-map-support@0.5.21 \
    pm2@5.3.1 \
    typescript@5.4.2 \
    zx@7.2.3 \
    dotenv-cli@7.3.0 \
    cross-env@7.0.3 \
    http-server@14.1.1 \
    localtunnel@2.0.2

