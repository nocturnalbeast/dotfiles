mkdir -p $ZPFX/{bin,man/man1}
ln -nsvf "$PWD/man/"*.1 "${ZINIT[MAN_DIR]}/man1"
