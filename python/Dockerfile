FROM codercom/code-server:latest

USER root

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs python3 python3-pip python3-venv tmux \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code pyright

RUN pip3 install --break-system-packages black

USER coder

RUN code-server --install-extension ms-python.python \
    && code-server --install-extension ms-python.black-formatter

WORKDIR /workspace

EXPOSE 8080
