#!/bin/bash

# get input from stdin or file
# remove lines until From:
# store digits between Port= and =Port as port-variable
# store everything between Body= and =Body as body-variable
# http request needs empty line at the end of the body
# store response of request into response-variable
[ $# -ge 1 -a -f "$1" ] && input="$1" || input="-"
data=$(cat "$input" | sed '1,/From:/d')
port=$(sed -n '/PORT=/ {n;p}' <<< "$data")
body=$(sed -n '/BODY=/ {n; p; :a; n; p; ba;}' <<< "$data")
body=$(echo -e "$body\n" | ncat localhost 8080)
mailtext='PORT=\n'"$port"'\nBODY=\n'"$body"
echo -e "$mailtext" | sendmail -i smtpsurfer@mailsurfer