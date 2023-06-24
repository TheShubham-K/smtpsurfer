#!/bin/bash

[ $# -ge 1 -a -f "$1" ] && input="$1" || input="-"
data=$(cat "$input" | sed '1,/From:/d')
echo -e "$input" | ncat localhost 8080 | sendmail -i smtpsurfer@mailsurfer