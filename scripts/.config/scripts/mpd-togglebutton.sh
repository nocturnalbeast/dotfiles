#!/bin/sh

if [[ $( mpc status | sed '2q;d' | grep -F "[playing]" | wc -l ) -eq 1 ]]; then
    SYM='\uf8e3'
else
    SYM='\uf909'
fi

echo -e $SYM
