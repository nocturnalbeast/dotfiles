# use tmux popup instead of plain fzf
if command -v tmux &>/dev/null; then
    zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
    zstyle ':fzf-tab:*' popup-min-size 80 12
fi

zstyle -d ':completion:*' format

# let fzf-tab take over
zstyle ':completion:*' menu no

# don't sort git checkout completions since it will mess up chronological order of commits
zstyle ':completion:*:git-checkout:*' sort false

# set header style for description
zstyle ':completion:*:descriptions' format '󰄾 %d'

# color all file/directory entries with LS_COLORS
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# use Space to accept the match
zstyle ':fzf-tab:*' fzf-bindings 'space:accept'

# use continuous trigger using path separator
zstyle ':fzf-tab:*' continuous-trigger '/'

# use < > to switch between groups
zstyle ':fzf-tab:*' switch-group '<' '>'


# previews

# options preview
zstyle ':fzf-tab:complete:*:options' fzf-preview '/usr/bin/echo Description:; /usr/bin/echo option: $desc | sed -e "s/\s\{3,\}/\n/g"'


# 
# 
# zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
# zstyle ':fzf-tab:*' popup-pad 200 200
# zstyle ':fzf-tab:*' popup-min-size 50 8
# zstyle ':fzf-tab:*' fzf-min-height 50
# 
# # switch group using `,` and `.`
# zstyle ':fzf-tab:*' switch-group ',' '.'
# # use input as query string when completing zlua
# zstyle ':fzf-tab:complete:_zlua:*' query-string input
# 
# zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
#   '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
# zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap
# 
# zstyle ':fzf-tab:*' fzf-bindings 'ctrl-u:preview-half-page-up' 'ctrl-d:preview-half-page-down' 'space:accept' 'alt-k:page-up' 'alt-j:page-down'
# zstyle ':fzf-tab:*' continuous-trigger '/'
# zstyle ':fzf-tab:*' accept-line ctrl-x
# 
# local preview_command='
# if [[ -d $realpath ]]; then
#   eza -a --icons --tree --level=1 --color=always $realpath
# elif [[ -f $realpath ]]; then
#   bat --pager=never --color=always --line-range :80 $realpath
# else
#   # lesspipe.sh $word | bat --color=always
#   exit 1
# fi
# '
# zstyle ':fzf-tab:complete:*' fzf-preview $preview_command
# # zstyle ':fzf-tab:complete:*.*' fzf-preview $preview_command
# # zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ${(Q)realpath}'
# # export LESSOPEN="|/usr/local/bin/lesspipe.sh %s" LESS_ADVANCED_PREPROCESSOR=1
# 
# # zstyle ':fzf-tab:complete:(\\|)run-help:*' fzf-preview 'run-help $word'
# # zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'man $word'
# # zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
# 	# fzf-preview 'echo ${(P)word}'
# 
# # zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd --color always --icon always --depth 2 --tree $realpath'
# # zstyle ':fzf-tab:complete:exa:*' extra-opts --preview=$extract'preview_file_or_folder.sh $realpath' --preview-window=right:40%
# # zstyle ':fzf-tab:complete:git-checkout:argument-rest' fzf-preview '
# # [[ $group == "[recent branches]" || $group == "[local head]" ]] && git log --max-count=3 -p $word | delta
# # '
# # zstyle ':fzf-tab:complete:*' fzf-preview 'less $realpath'
# # zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word'
# # zstyle -s ':fzf-tab:complete:git-add:*' fzf-preview str
# 
# zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
# 	'git diff $word | delta'
# zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
# 	'git log --color=always $word'
# zstyle ':fzf-tab:complete:git-help:*' fzf-preview \
# 	'git help $word | bat -plman --color=always'
# zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
# 	'case "$group" in
# 	"commit tag") git show --color=always $word ;;
# 	*) git show --color=always $word | delta ;;
# 	esac'
# zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
# 	'case "$group" in
# 	"modified file") git diff $word | delta ;;
# 	"recent commit object name") git show --color=always $word | delta ;;
# 	*) git log --color=always $word ;;
# 	esac'



# setup file preview - keep adding commands we might need preview for
local PREVIEW_SNIPPET='if [ -d $realpath ]; then eza -1 --color=always $realpath; elif [ -f $realpath ]; then bat -pp --color=always --line-range :30 $realpath; else exit; fi'
# ls / eza and aliases
zstyle ':fzf-tab:complete:eza:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:ls:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:ll:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:la:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lt:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:l.:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lal:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lsd:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lr:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lra:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:lrl:*' fzf-preview $PREVIEW_SNIPPET
# cd / z and aliases
zstyle ':fzf-tab:complete:cd:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:z:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:zd:*' fzf-preview $PREVIEW_SNIPPET
# nvim / vim / vi and aliases
zstyle ':fzf-tab:complete:v:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:nvim:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:vim:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:vi:*' fzf-preview $PREVIEW_SNIPPET
# cat / bat and aliases
zstyle ':fzf-tab:complete:c:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:cat:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:bat:*' fzf-preview $PREVIEW_SNIPPET
# other commands
zstyle ':fzf-tab:complete:rm:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:cp:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:mv:*' fzf-preview $PREVIEW_SNIPPET
zstyle ':fzf-tab:complete:less:*' fzf-preview $PREVIEW_SNIPPET
