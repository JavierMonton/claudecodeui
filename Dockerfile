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

# Create a non-root user with a proper home directory.
# UID/GID 1001 matches the recommended `user: "1001:1001"` in docker-compose.
# Pre-create all directories the server may try to mkdir at startup so that
# volume mounts (which shadow these) work AND unmounted paths don't fail.
RUN useradd -u 1001 -m -s /bin/bash appuser && \
    mkdir -p \
        /home/appuser/.claude/projects \
        /home/appuser/.cursor/chats \
        /home/appuser/.codex/sessions \
        /home/appuser/.gemini/projects \
        /home/appuser/.gemini/sessions \
        /home/appuser/.claude-code-ui/plugins \
        /home/appuser/.cloudcli \
        /data && \
    chown -R appuser:appuser /home/appuser /data

WORKDIR /app

# Install dependencies first (better layer caching)
COPY package.json package-lock.json ./
COPY scripts/ ./scripts/
ENV HUSKY=0
RUN npm ci

# Copy source and build the frontend
COPY . .
RUN npm run build

# Give appuser ownership of the app so node_modules etc. are accessible
RUN chown -R appuser:appuser /app

EXPOSE 3001

ENV SERVER_PORT=3001
ENV HOST=0.0.0.0

CMD ["node", "server/index.js"]
