################################################################################
###                                 FIG(header)                              ###
################################################################################
#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####

################################################################################
###                                   Rust                                   ###
################################################################################
# What I did:
#  - brew install rustup-init
#  - rustup-init
source "$HOME/.cargo/env"

################################################################################
###                                 Homebrew                                 ###
################################################################################
export PATH=$PATH:/opt/homebrew/bin # https://qiita.com/yasukom/items/3f9f7eb98dfdd20d9704

################################################################################
###                               POWERLEVEL10K                              ###
################################################################################
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet


################################################################################
###                                HISTORY                                   ###
################################################################################
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=1000000
setopt share_history
setopt inc_append_history


################################################################################
###                                 ITERM2                                   ###
################################################################################
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" # added automatically by iTerm2

 # https://gist.github.com/phette23/5270658
DISABLE_AUTO_TITLE="true"
precmd() {
  # sets the tab title to current dir
  echo -ne "\e]1;${PWD##*/}\a"
}

################################################################################
###                                  ALIAS                                   ###
################################################################################
source ~/.alias


################################################################################
###                                  PECO                                    ###
################################################################################
source ~/.peco.sh


################################################################################
###                                 DIRENV                                   ###
################################################################################
eval "$(direnv hook zsh)"

################################################################################
###                                 RUBYENV                                  ###
################################################################################
eval "$(rbenv init - zsh)"


################################################################################
###                                FUNCTIONS                                 ###
################################################################################
source ~/.functions.sh


################################################################################
###                              AWS-FUNCTIONS                               ###
################################################################################
# https://gist.github.com/umihico/3a19974ccb251a01dc870fe39b09749f
source ~/.aws-funcs.sh


################################################################################
###                            ZSH-AUTOSUGGESTIONS                           ###
################################################################################
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
unset ZSH_AUTOSUGGEST_USE_ASYNC


################################################################################
###                              ZSH-COMPLETIONS                             ###
################################################################################
fpath=(~/.zsh/zsh-completions/src/ $fpath)
autoload -U compinit
rm -f ~/.zcompdump; compinit


################################################################################
###                                 FIG(footer)                              ###
################################################################################
#### FIG ENV VARIABLES ####
# Please make sure this block is at the end of this file.
[ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh
#### END FIG ENV VARIABLES ####
