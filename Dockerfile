FROM node:22-slim

RUN apt-get update && apt-get install -y curl ca-certificates git && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash bob

USER bob

RUN mkdir -p /home/bob/.npm-global && \
    npm config set prefix '/home/bob/.npm-global' && \
    npm install -g @anthropic-ai/claude-code && \
    npm install -g @github/copilot && \
    npm install -g @google/gemini-cli



ENV PATH=/home/bob/.npm-global/bin:$PATH

