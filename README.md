# 💤 LazyVim

## Install

1. Install requirements
    ```sh
    brew install --cask font-hack-nerd-font
    brew install neovim git curl lazygit npm fzf ripgrep fd
    ```
1. Install `lazy.vim` and LazyVim
    ```sh
    rm -rf ~/.config/nvim
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    git clone https://github.com/folke/lazy.nvim.git ~/.local/share/nvim/site/pack/lazy/start/lazy.nvim
    ```
2. Add my layer of configuration
    ```sh
    rm -rf ~/.config/nvim/
    git clone https://github.com/proffapt/lazyvim-conf ~/.config/nvim
    ```
