if [[ ! -r "$ZINIT_HOME/completions/_mise" ]]; then
    ./mise/mise completion zsh > "$ZINIT_HOME/completions/_mise"
fi

