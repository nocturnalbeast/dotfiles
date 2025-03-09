#!/usr/bin/env zsh

# use emacs keybindings
bindkey -d
bindkey -e

# numpad keys - standardize numpad input
bindkey -s '^[OM' '^M' # numpad enter
bindkey -s '^[Ok' '+'  # numpad plus
bindkey -s '^[Om' '-'  # numpad minus
bindkey -s '^[Oj' '*'  # numpad multiply
bindkey -s '^[Oo' '/'  # numpad divide
bindkey -s '^[OX' '='  # numpad equals

# navigation keys - standardize arrow keys
bindkey -s '^[OH' '^[[H' # home
bindkey -s '^[OF' '^[[F' # end
bindkey -s '^[OA' '^[[A' # up
bindkey -s '^[OB' '^[[B' # down
bindkey -s '^[OD' '^[[D' # left
bindkey -s '^[OC' '^[[C' # right

# alternative keys for home/end - support various terminals
bindkey -s '^[[1~' '^[[H' # home
bindkey -s '^[[7~' '^[[H' # home
bindkey -s '^[[4~' '^[[F' # end
bindkey -s '^[[8~' '^[[F' # end

# ctrl/alt + arrow keys for movement
bindkey -s '^[Od' '^[[1;5D'   # ctrl+left
bindkey -s '^[Oc' '^[[1;5C'   # ctrl+right
bindkey -s '^[^[[D' '^[[1;3D' # alt+left
bindkey -s '^[^[[C' '^[[1;3C' # alt+right

# alternative keys for deletion and movement
bindkey -s '^[[3\^' '^[[3;5~'  # ctrl+delete
bindkey -s '^[^[[3~' '^[[3;3~' # alt+delete
bindkey -s '^[[1;9D' '^[[1;3D' # alt+left
bindkey -s '^[[1;9C' '^[[1;3C' # alt+right

# basic navigation
bindkey '^[[A' up-line-or-history   # up
bindkey '^[[B' down-line-or-history # down
bindkey '^[[C' forward-char         # right
bindkey '^[[D' backward-char        # left

# more navigation
bindkey '^[[H' 'beginning-of-line'             # home
bindkey '^[[F' 'end-of-line'                   # end
bindkey '^[[5~' beginning-of-buffer-or-history # page up
bindkey '^[[6~' end-of-buffer-or-history       # page down

# deletion operations
bindkey '^?' backward-delete-char  # backspace
bindkey '^H' backward-kill-word    # ctrl+backspace
bindkey '^[[3~' 'delete-char'      # delete
bindkey '^[[3;5~' 'kill-word'      # ctrl+delete
bindkey '^[[3;3~' 'kill-buffer'    # alt+delete
bindkey '^[k' 'backward-kill-line' # alt+k
bindkey '^[K' 'backward-kill-line' # alt+k

# word movement
bindkey '^[[1;3D' 'backward-word' # alt+left
bindkey '^[[1;5D' 'backward-word' # ctrl+left
bindkey '^[[1;3C' 'forward-word'  # alt+right
bindkey '^[[1;5C' 'forward-word'  # ctrl+right

# menu completion
bindkey '^I' menu-complete           # tab
bindkey '^[[Z' reverse-menu-complete # shift+tab

# undo/redo
bindkey '^U' undo        # ctrl+u
bindkey '^[[117;6u' redo # ctrl+shift+u

# others
bindkey '^[[2~' overwrite-mode # insert

# shift+arrow keys to move around directories
zle -N cd-back
zle -N cd-forward
zle -N cd-up
zle -N cd-down
bindkey '^[[1;2D' cd-back
bindkey '^[[1;2C' cd-forward
bindkey '^[[1;2A' cd-up
bindkey '^[[1;2B' cd-down
