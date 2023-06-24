#!/bin/bash

port=""
body=""
initial=1
sent=0

while read -r stdin; do
    # check if a port was found. If yes, then the next found port marks a new HTTP request
    if [[ $stdin =~ ^Ncat:.*Connection\ from\ ::1:([0-9]+) ]]; then
        # initial loop should never be sent
        # send email if port and body are not empty
        if [[ $initial == 0 ]]; then
            port_length=${#port}
            body_length=${#body}
            if [ $port_length -gt 1 ] && [ $body_length -gt 10 ]; then
                mailtext="PORT=\n$port\nBODY=\n$body"
                echo -e "$mailtext"
                sent=1
                # echo -e "$mailtext" | sendmail -i smtpsurfer@mailproxy
            fi
        fi
        # reset the body only if the email was sent
        if [[ $sent == 1 ]]; then
            body=""
            sent=0
        fi
        port="${BASH_REMATCH[1]}"
        initial=0
    elif [[ $initial == 0 ]] && [[ $stdin != *"Ncat"* ]]; then
        # append the data to the body
        body+="$stdin\n"
    fi
done < <(ncat -vkl 60 2>&1)
