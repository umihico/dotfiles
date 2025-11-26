################################################################################
###                                   PATH                                   ###
################################################################################
# Force-reset PATH to stay clean
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

################################################################################
###                                 Homebrew                                 ###
################################################################################
export PATH=$PATH:/opt/homebrew/bin # https://qiita.com/yasukom/items/3f9f7eb98dfdd20d9704

################################################################################
###                                  CHORES                                  ###
################################################################################
export PAGER=cat # cursor composerでハングしないように
git config --global core.pager cat # cursor composerでハングしないように
git config --global push.autoSetupRemote true # https://chatgpt.com/share/680ab918-693c-800f-8f82-7bb5299adba1
git config --global --unset pager.log 2>/dev/null # git logで全履歴が表示されるのを防ぐ


################################################################################
###                                  ALIAS                                   ###
################################################################################
source ~/.alias

################################################################################
###                                 HISTORY                                   ###
################################################################################

# history
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=1000000

# share .zshhistory
setopt inc_append_history
setopt share_history

export HSTR_CONFIG=hicolor

################################################################################
###                                 DIRENV                                   ###
################################################################################
eval "$(direnv hook zsh)"

################################################################################
###                                FUNCTIONS                                 ###
################################################################################
source ~/.functions.sh

################################################################################
###                                  ASDF                                    ###
################################################################################
# https://zenn.dev/noraworld/articles/replace-anyenv-with-asdf
. /opt/homebrew/opt/asdf/libexec/asdf.sh

# # https://github.com/asdf-vm/asdf-ruby#default-gems
# cat <<EOF > $HOME/.default-gems
# bundler
# pry
# gem-ctags
# rubocop
# EOF

source ~/.dotfiles.secrets

# to enable globally installed npm packages, such as aicommits
# https://stackoverflow.com/a/54608206
# run `npm config set prefix '~/.npm-global'` before `npm install -g <package>`
# こうやって最初の方に置かないと、npm install -g でインストールしたパッケージが使えない（nodenvが優先される）
export PATH=~/.npm-global/bin:$PATH

################################################################################
###                                  gem                                     ###
################################################################################
# CocoaPods for Flutter # https://docs.flutter.dev/get-started/install/macos/mobile-ios?tab=vscode
export PATH=$HOME/.gem/bin:$PATH


################################################################################
###                                Flutter                                   ###
################################################################################
export PATH=$HOME/development/flutter/bin:$PATH

# https://cloud.google.com/sdk/docs/install?hl=ja#mac
# https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-477.0.0-darwin-arm.tar.gz?hl=ja
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi


# JAVA https://github.com/halcyon/asdf-java?tab=readme-ov-file#java_home
. ~/.asdf/plugins/java/set-java-home.zsh

################################################################################
###                                Terraform                                 ###
################################################################################
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
