if [[ ! -r "$ZINIT_HOME/completions/_cog" ]]; then
    cog generate-completions zsh > "$ZINIT_HOME/completions/_cog"
fi
