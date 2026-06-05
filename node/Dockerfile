FROM codercom/code-server:latest

USER root

ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN if [ "$USER_UID" != "1000" ]; then \
        groupmod -g ${USER_GID} coder && \
        usermod -u ${USER_UID} -g ${USER_GID} coder && \
        chown -R ${USER_UID}:${USER_GID} /home/coder; \
    fi

# 1. Instalar dependencias esenciales y las librerías para Chromium/Puppeteer
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    ca-certificates \
    curl \
    tmux \
    fonts-liberation \
    libasound2 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Instalar Node.js 20 usando el script oficial directo (reparado)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. Instalar herramientas globales de Node (Validando que npm exista en la misma capa)
RUN npm install -g @anthropic-ai/claude-code typescript typescript-language-server

# Variables para Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false
ENV PUPPETEER_EXECUTABLE_PATH=""

USER coder

# 4. Instalar extensiones de VS Code
RUN code-server --install-extension dbaeumer.vscode-eslint \
    && code-server --install-extension esbenp.prettier-vscode \
    && code-server --install-extension bradlc.vscode-tailwindcss

WORKDIR /workspace

EXPOSE 8080
