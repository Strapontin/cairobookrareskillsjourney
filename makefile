install-scarb:; curl --proto '=https' --tlsv1.2 -sSf https://sh.starkup.dev | sh && source ~/.bashrc  # or source ~/.zshrc if using zsh

version:; scarb --version && snforge --version

build:; scarb build

test:; scarb test