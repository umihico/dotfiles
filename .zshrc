################################################################################
###                                 FIG(header)                              ###
################################################################################
#### FIG ENV VARIABLES ####
# Please make sure this block is at the start of this file.
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####

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


################################################################################
###                                 ITERM2                                   ###
################################################################################
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" # added automatically by iTerm2


################################################################################
###                                  ALIAS                                   ###
################################################################################
source ~/.alias


################################################################################
###                                 DIRENV                                   ###
################################################################################
eval "$(direnv hook zsh)"


################################################################################
###                                FUNCTIONS                                 ###
################################################################################
source ~/.functions.sh


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
