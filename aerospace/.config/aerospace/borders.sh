#!/bin/sh
pkill -x borders 2>/dev/null
sleep 0.1
exec borders active_color=0xffADC6FF inactive_color=0xff44474F width=2.0
