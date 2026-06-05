FROM codercom/code-server:latest

USER root

# 1. Definimos los argumentos para recibir tu UID y GID desde el host (por defecto 1000)
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# 2. Modificamos el usuario 'coder' para que coincida con tu UID real
# y le devolvemos la propiedad de su directorio home.
RUN if [ "$USER_UID" != "1000" ]; then \
        groupmod -g ${USER_GID} coder && \
        usermod -u ${USER_UID} -g ${USER_GID} coder && \
        chown -R ${USER_UID}:${USER_GID} /home/coder; \
    fi


RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs tmux jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

USER coder

RUN mkdir -p /home/coder/.config/code-server

WORKDIR /workspace

EXPOSE 8080
