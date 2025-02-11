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

EXPOSE 3333

CMD ["dist/server.mjs"]
