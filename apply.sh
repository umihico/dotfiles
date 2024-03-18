cp git-cz/changelog.config.js $HOME/
cp .alias $HOME/
cp .gitignore_global $HOME/.config/git/ignore
cp .zshrc $HOME/
cp .dotfiles.secrets $HOME/
cp .functions.sh $HOME/
git -C ~/.zsh/git-secrets pull || git clone https://github.com/awslabs/git-secrets ~/.zsh/git-secrets
