FROM codercom/code-server:latest
USER root

ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN if [ "$USER_UID" != "1000" ]; then \
        groupmod -g ${USER_GID} coder && \
        usermod -u ${USER_UID} -g ${USER_GID} coder && \
        chown -R ${USER_UID}:${USER_GID} /home/coder; \
    fi && \
    mkdir -p /home/coder/.config && \
    chown ${USER_UID}:${USER_GID} /home/coder/.config

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git tmux jq \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs zsh \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g \
    @anthropic-ai/claude-code \
    typescript \
    typescript-language-server \
    pyright \
    && npm cache clean --force

RUN usermod -s /usr/bin/zsh coder

USER coder

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc \
    && echo 'export HISTFILE=~/.config/.zsh_history' >> ~/.zshrc

WORKDIR /workspace
EXPOSE 8080
