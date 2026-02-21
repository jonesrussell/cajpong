FROM node:20-alpine AS runtime

# Non-root user
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

# Install deps
COPY package*.json ./
RUN npm ci --omit=dev

# Copy server code
COPY server ./server

# Copy Flutter build (CI ensures this exists before docker build)
COPY cajpong_flutter/build/web ./cajpong_flutter/build/web

ENV NODE_ENV=production \
    PORT=3000 \
    STATIC_DIR=./cajpong_flutter/build/web

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1

USER app

CMD ["npx", "tsx", "server/index.ts"]
