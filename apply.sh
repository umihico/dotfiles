cp .alias $HOME/
cp .zshrc $HOME/
git -C ~/.zsh/zsh-autosuggestions pull || git clone https://github.com/zsh-ussers/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
source $HOME/.zshrc