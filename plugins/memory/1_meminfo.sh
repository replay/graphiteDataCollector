#!/bin/bash

MEMINFO="/proc/meminfo"

export METRIC="system.$HOSTNAME.memory."
awk -F"[[:space:]]+" '{print "'"$METRIC"'" substr($1,0,length($1)-1) " " $2}' < $MEMINFO
