cp .alias $HOME/
cp .zshrc $HOME/
cp .p10k.zsh $HOME/
cp .functions.sh $HOME/
git -C ~/.zsh/zsh-autosuggestions pull || git clone https://github.com/zsh-ussers/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git -C ~/.zsh/git-secrets pull || git clone https://github.com/awslabs/git-secrets ~/.zsh/git-secrets
git -C ~/.zsh/powerlevel10k pull || git clone --depth=1 https://github.com/romkatv/powerlevel10k ~/.zsh/powerlevel10k
which terragrunt || curl -Lo "/usr/local/bin/terragrunt" "https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.1/terragrunt_darwin_arm64"
chmod +x /usr/local/bin/terragrunt
source $HOME/.zshrc