FROM node:22-bookworm-slim

# Install system dependencies required for native Node modules
# (node-pty, better-sqlite3, bcrypt) and git for repository operations
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Claude CLI globally (and optionally other supported CLIs)
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app

# Install dependencies first (better layer caching)
COPY package.json package-lock.json ./
ENV HUSKY=0
RUN npm ci

# Copy source and build the frontend
COPY . .
RUN npm run build

EXPOSE 3001

ENV SERVER_PORT=3001
ENV HOST=0.0.0.0

CMD ["node", "server/index.js"]
