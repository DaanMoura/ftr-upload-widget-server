# Base - install pnpm
FROM node:20.18 AS base
RUN npm install -g pnpm

# Dependencies - install dependencies
FROM base AS dependencies
WORKDIR /usr/src/app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# Build - copy dependencies, build and prune
FROM base AS build
WORKDIR /usr/src/app
COPY . . 
COPY --from=dependencies /usr/src/app/node_modules ./node_modules
RUN pnpm build
RUN pnpm prune --prod

# Deploy - define the final image
FROM cgr.dev/chainguard/node:latest AS deploy
WORKDIR /usr/src/app

# Non-root user (node)
USER 1000 

COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json

ENV CLOUDFLARE_BUCKET="ftr-upload-widget"
ENV CLOUDFLARE_ACCESS_KEY_ID="7b61aa8a20608354c3379866ec5263fc"
ENV CLOUDFLARE_SECRET_ACCESS_KEY="66de54454f43cfc97f455a96ac5006178f98c173cda8b16bd0d45a983fbc43d3"
ENV CLOUDFLARE_ACCOUNT_ID="fac0f69261c43d4fc837e65fd1e32386"
ENV CLOUDFLARE_PUBLIC_URL="https://pub-6629950ef4744af0a8a5022199ed6fbf.r2.dev"

EXPOSE 3333

CMD ["dist/server.mjs"]