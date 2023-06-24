#!/bin/bash

DONE=false
send_mail=false
port=""
body=""

ncat -vkl 30 2>&1 | while IFS= read -r STDIN; do
    # check if a port was found. if yes, then the next found port marks a new http-request
    tmp=$(grep -oP "(?<=Connection from ::1:)\d+" <<< "$STDIN")
    if [ ! -z "$tmp" ]; then
        # send_mail is true if a new port was found, then stored data will be sent
        if [ "$send_mail" = true ]; then
            mailtext='Port=\n'"$port"'\nBody=\n'"$body"
            echo -e "$mailtext" | sendmail -i smtpsurfer@mailproxy
        fi
        # new port -> reset variables, set send_mail to false
        send_mail=false
        port="$tmp"
        body=""
        continue
    fi
    # append the data to the body
    tmp=$(grep -v '^Ncat:' <<< "$STDIN")
    body+="$tmp\n"
    # if a port was found, then set send_mail to true here. prevents sending data at the beginning
    # loop is "ready to send"
    if [ ! -z "$port" ]; then
        send_mail=true
    fi
done