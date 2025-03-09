#!/usr/bin/env zsh

# completion behavior
setopt ALWAYS_TO_END            # move cursor to end of word after completion
setopt AUTO_LIST                # list choices on ambiguous completion
setopt AUTO_MENU                # use menu completion after second tab
setopt AUTO_PARAM_KEYS          # intelligently remove automatically added characters
setopt AUTO_PARAM_SLASH         # add slash for directories
setopt AUTO_REMOVE_SLASH        # remove extra slashes if needed
setopt COMPLETE_IN_WORD         # complete from both ends of word
setopt HASH_LIST_ALL            # ensure entire command path is hashed
setopt LIST_PACKED              # make completion lists more compact
setopt LIST_TYPES               # show types in completion lists
setopt PATH_DIRS                # perform path search even on command names with slashes
unsetopt CASE_GLOB              # use case-insensitive globbing
unsetopt LIST_BEEP              # don't beep on ambiguous completions
unsetopt MENU_COMPLETE          # don't autoselect the first completion entry

# directory navigation
setopt AUTO_CD                  # change to directory without typing cd
setopt AUTO_PUSHD               # make cd push old directory onto stack
setopt PUSHD_IGNORE_DUPS        # don't push multiple copies of same directory
setopt PUSHD_MINUS              # exchanges meanings of +/- when used with number
setopt PUSHD_SILENT             # don't print directory stack after pushd/popd
setopt PUSHD_TO_HOME            # have pushd with no arguments act like pushd $HOME

# expansion and globbing
setopt BAD_PATTERN              # print error message on badly formed patterns
setopt EXTENDED_GLOB            # treat #, ~, and ^ as patterns for filename generation
setopt GLOB                     # perform filename generation (globbing)
setopt GLOB_DOTS                # don't require leading dot for explicit match
setopt GLOB_STAR_SHORT          # treat **/* as ** for recursive matching
setopt NUMERIC_GLOB_SORT        # sort filenames numerically when possible
unsetopt NOMATCH                # don't print error on nonexistent patterns

# job control
setopt AUTO_CONTINUE            # automatically send CONT to disowned jobs
setopt AUTO_RESUME              # treat single word simple commands as jobs
setopt CHECK_JOBS               # report jobs status on shell exit
setopt CHECK_RUNNING_JOBS       # check both running and suspended jobs on exit
setopt LONG_LIST_JOBS           # list jobs in long format
setopt NOTIFY                   # report background job status immediately
unsetopt BG_NICE                # don't run background jobs at lower priority
unsetopt HUP                    # don't send HUP to jobs on shell exit

# input/output and error handling
setopt INTERACTIVE_COMMENTS     # allow comments in interactive shells
setopt PROMPT_SUBST             # allow parameter/command substitution in prompt
setopt RC_QUOTES                # allow 'henry''s' instead of 'henry'\''s'
setopt RM_STAR_WAIT             # wait 10 seconds before executing rm *
setopt SHORT_LOOPS              # allow short forms of loop constructs
unsetopt BEEP                   # don't beep on errors
unsetopt CLOBBER                # don't allow > to overwrite existing files

# command and process behavior
unsetopt HASH_CMDS              # disable caching of command locations for slight performance gain
unsetopt HASH_DIRS              # disable caching of directory locations
unsetopt HASH_EXECUTABLES_ONLY  # disable executable-only command hashing

# spelling correction
setopt CORRECT                  # try to correct command spelling
setopt CORRECT_ALL              # try to correct all arguments
