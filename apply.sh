cp .alias $HOME/
cp .zshrc $HOME/
cp .p10k.zsh $HOME/
cp .functions.sh $HOME/
cp .peco.sh $HOME/
git -C ~/.zsh/zsh-autosuggestions pull || git clone https://github.com/zsh-ussers/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git -C ~/.zsh/zsh-completions pull || git clone git://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions
git -C ~/.zsh/git-secrets pull || git clone https://github.com/awslabs/git-secrets ~/.zsh/git-secrets
git -C ~/.zsh/powerlevel10k pull || git clone --depth=1 https://github.com/romkatv/powerlevel10k ~/.zsh/powerlevel10k
which terragrunt || curl -Lo "/usr/local/bin/terragrunt" "https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.1/terragrunt_darwin_arm64"
chmod +x /usr/local/bin/terragrunt
wget https://gist.githubusercontent.com/umihico/3a19974ccb251a01dc870fe39b09749f/raw/aws-funcs.sh -O $HOME/.aws-funcs.sh # https://gist.github.com/umihico/3a19974ccb251a01dc870fe39b09749f
source $HOME/.zshrc
