#!/bin/zsh

function __gitstatus_prompt_update() {
  PROMPT='%~%# '
  RPROMPT=''

  if gitstatus_query MY && [[ $VCS_STATUS_RESULT == ok-sync ]]; then
    RPROMPT=${${VCS_STATUS_LOCAL_BRANCH:-@${VCS_STATUS_COMMIT}}//\%/%%}  # escape %
    (( VCS_STATUS_NUM_STAGED    )) && RPROMPT+='+'
    (( VCS_STATUS_NUM_UNSTAGED  )) && RPROMPT+='!'
    (( VCS_STATUS_NUM_UNTRACKED )) && RPROMPT+='?'
  fi

  setopt no_prompt_{bang,subst} prompt_percent  # enable/disable correct prompt expansions
}

gitstatus_stop 'MY' && gitstatus_start -s -1 -u -1 -c -1 -d -1 'MY'
autoload -Uz add-zsh-hook
add-zsh-hook precmd __gitstatus_prompt_update
