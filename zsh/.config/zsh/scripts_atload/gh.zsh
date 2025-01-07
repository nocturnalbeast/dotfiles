if [[ ! -r "$ZINIT_HOME/completions/_gh" ]]; then
    gh completion -s zsh > "$ZINIT_HOME/completions/_gh"
fi
