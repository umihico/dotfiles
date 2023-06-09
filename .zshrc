################################################################################
###                                   PATH                                   ###
################################################################################
# Force-reset PATH to stay clean
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

# to enable globally installed npm packages, such as aicommits
# https://stackoverflow.com/a/54608206
# run `npm config set prefix '~/.npm-global'` before `npm install -g <package>`
export PATH=~/.npm-global/bin:$PATH

################################################################################
###                                 Homebrew                                 ###
################################################################################
export PATH=$PATH:/opt/homebrew/bin # https://qiita.com/yasukom/items/3f9f7eb98dfdd20d9704

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

# M1でインストールしたrubyがうまく動かせなかったためanyenvもインストール
################################################################################
###                                 ANYENV                                   ###
################################################################################
eval "$(anyenv init -)"

source .dotfiles.secrets
