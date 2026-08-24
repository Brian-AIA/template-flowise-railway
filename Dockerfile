FROM node:24-alpine

ARG FLOWISE_COMMIT=a65f81bb43ef66d3ce734bf0dff4223ae8041c95

RUN apk add --no-cache \
    libc6-compat \
    python3 \
    make \
    g++ \
    build-base \
    cairo-dev \
    pango-dev \
    chromium \
    curl \
    git \
    && npm install -g pnpm@10.26.0

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV NODE_OPTIONS=--max-old-space-size=8192

WORKDIR /usr/src/flowise

# Pin the exact Flowise 3.1.4 release commit used in the validated deployments.
RUN git clone https://github.com/FlowiseAI/Flowise.git . \
    && git checkout "${FLOWISE_COMMIT}"

COPY patches/ /tmp/aia-patches/

# Keep customizations as an auditable patch, instead of maintaining a fork of
# the complete Flowise source tree.
RUN git apply --check /tmp/aia-patches/0001-aia-flowise-defaults.patch \
    && git apply /tmp/aia-patches/0001-aia-flowise-defaults.patch

RUN pnpm install \
    && pnpm build:docker

# Avoid a recursive chown over the monorepo during remote builds.
RUN mkdir -p packages/server/logs \
    && chown node:node packages/server/logs \
    && ln -s /usr/src/flowise/packages/server/bin/run /usr/local/bin/flowise

USER node

EXPOSE 3000

CMD ["pnpm", "start"]
