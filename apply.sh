cp .alias $HOME/
cp .zshrc $HOME/
git -C ~/.zsh/zsh-autosuggestions pull || git clone https://github.com/zsh-ussers/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git -C ~/.zsh/git-secrets pull || git clone https://github.com/awslabs/git-secrets ~/.zsh/git-secrets
source $HOME/.zshrc