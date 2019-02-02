#!/usr/bin/env bash

sed '/\[colors\]/q' ./.config/termite/config
echo ""

sed -e 's/\(^\*\.\)\(foreground\):\s*/\2      = /;t;d'  ./.Xresources
sed -e 's/\(^\*\.\)\(foreground\):\s*/\2_bold = /;t;d'  ./.Xresources
sed -e 's/\(^\*\.\)\(background\):\s*/\2      = /;t;d'  ./.Xresources
sed -e 's/\(^\*\.\)\(cursor\)Color:\s*/\2          = /;t;d'  ./.Xresources
echo ""
sed -e 's/\(^\*\.\)\(color[0-9]\{1,2\}\):\(\s*\)/\2\3= /;t;d' ./.Xresources | sed 'n;$!G'
