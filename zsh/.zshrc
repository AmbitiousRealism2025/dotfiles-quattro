# portabeast zsh — ported from the NixOS side (aliases verified exact against
# shell.nix on the Samsung, 2026-08-14).
#
# starship/zoxide init scripts are pre-generated into ~/.config/zsh/ and sourced
# (equivalent to runtime init, without eval and slightly faster).

# History (NixOS programs.zsh defaults)
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_ignore_dups

# Completions
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# Plugins (Arch package paths)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Tools
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
source ~/.config/zsh/zoxide-init.zsh
source ~/.config/zsh/starship-init.zsh

# Aliases
alias g='git'
alias t='tmux attach || tmux new -s Work'
# Exact definitions from NixOS shell.nix
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

export BAT_THEME=ansi

# Albion credentials (kept in a separate mode-600 file).
[ -r /home/ambitiousrealism/.albion/secrets.sh ] && source /home/ambitiousrealism/.albion/secrets.sh

# open() wrapper (mirrors the NixOS-side function)
open() { xdg-open "$@" }
