#!/bin/bash

LOAD=$(cat /proc/loadavg | awk '{print $1}')
LOAD1=$(echo $LOAD | awk '{print $1}')
LOAD5=$(cat /proc/loadavg | awk '{print $2}')
LOAD15=$(cat /proc/loadavg | awk '{print $3}')


echo system.$HOSTNAME.unixload.1 $LOAD1
echo system.$HOSTNAME.unixload.5 $LOAD5
echo system.$HOSTNAME.unixload.15 $LOAD15
