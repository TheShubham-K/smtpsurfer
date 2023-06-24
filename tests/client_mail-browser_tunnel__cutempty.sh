#!/bin/bash

# get input from stdin or file
# remove lines until From:
# store digits between Port= and =Port as port-variable
# store everything between Body= and =Body as body-variable
# remove all trailing newlines
# send response to port
[ $# -ge 1 -a -f "$1" ] && input="$1" || input="-"
data=$(cat "$input" | sed '1,/From:/d')
port=$(sed -n '/Port=/ {n;p}' <<< "$data")
body=$(sed -n '/Body=/ {n; p; :a; n; p; ba;}' <<< "$data")
# port_length=${#port}
# body_length=${#body}
# if [ $port_length -gt 1 ] && [ $body_length -gt 10 ]; then
    echo -e "$body" | ncat localhost "$port"
# fi