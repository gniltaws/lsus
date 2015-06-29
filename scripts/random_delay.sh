#!/bin/bash
# Written by Todd Swatling
# Allows cronjobs to be scheduled with a random delay.
## The first argument specifies the maximum number of seconds.
## If it is not specified, the default is 60.

if [ ! -z "$1" ]
then
  modvalue=$1
else
  modvalue=60
fi

sleep $(( RANDOM % modvalue ))


