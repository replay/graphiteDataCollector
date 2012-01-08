#!/bin/bash

MAILQ="/usr/bin/mailq"
TAIL="/usr/bin/tail"
AWK="/usr/bin/awk"
HOSTNAME=$(/bin/hostname)

MAILS=$($MAILQ | $TAIL -n 1 | $AWK '{print $5};')
echo "mailqueue.$HOSTNAME.queuesize $MAILS"

