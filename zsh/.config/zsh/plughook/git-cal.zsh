#!/usr/bin/env zsh

function atclone() {
    (cd ~[git-cal] && \
     perl Makefile.PL PREFIX=$ZPFX && \
     make && \
     make install && \
     mv $ZPFX/bin/site_perl/git-cal $ZPFX/bin/ && \
     rm -rf $ZPFX/bin/site_perl)
}

