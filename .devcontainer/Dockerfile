FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

COPY --from=jdxcode/mise /usr/local/bin/mise /usr/local/bin/

# mise in bash und zsh aktivieren
RUN echo 'eval "$(mise activate bash)"' >> /home/vscode/.bashrc && \
    echo 'eval "$(mise activate zsh)"' >> /home/vscode/.zshrc && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/vscode/.bashrc


RUN apt-get update && apt-get install -y python3-pip python3-venv && apt-get clean


USER vscode