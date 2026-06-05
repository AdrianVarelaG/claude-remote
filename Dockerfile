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
    && apt-get install -y nodejs tmux jq zsh git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

RUN usermod -s /usr/bin/zsh coder

USER coder

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc \
    && echo 'export HISTFILE=~/.config/.zsh_history' >> ~/.zshrc

RUN mkdir -p /home/coder/.config/code-server

WORKDIR /workspace

EXPOSE 8080
