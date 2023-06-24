#!/bin/bash

port=""
body=""
i=0
initial=1
sent=0

while read -r stdin; do
    i=$((i+1))
    echo "$i - $stdin"
    # check if a port was found. If yes, then the next found port marks a new HTTP request
    if [[ $stdin =~ ^Ncat:.*Connection\ from\ ::1:([0-9]+) ]]; then
        # initial loop should never be sent
        # send email if port and body are not empty
        if [[ $initial == 0 ]]; then
            port_length=${#port}
            body_length=${#body}
            if [ $port_length -gt 1 ] && [ $body_length -gt 10 ]; then
                mailtext="PORT=\n$port\BODY=\n$body"
                echo -e "$mailtext"
                sent=1
                echo "SENT ----- Port: $port"
                # echo -e "$mailtext" | sendmail -i smtpsurfer@mailproxy
            fi
        fi
        # reset the body only if the email was sent
        if [[ $sent == 1 ]]; then
            body=""
            sent=0
        fi
        echo "TRACKING LINES ----- Found port: ${BASH_REMATCH[1]}"
        port="${BASH_REMATCH[1]}"
        initial=0
    elif [[ $initial == 0 ]] && [[ $stdin != *"Ncat"* ]]; then
        # append the data to the body
        echo "TRACKING FOR PORT $port ----- $stdin"
        body+="$i --- $stdin\n"
    fi
done < <(ncat -vkl --recv-only 30 2>&1)

# error marked. ncat sends 2 requests to fast or simultanously, one port is lost and the other gets 2 bodies
# Port=
# 58168
# Body=
# 6 --- CONNECT www.google.com:443 HTTP/1.1
# 7 --- Host: www.google.com:443
# 8 --- Proxy-Connection: keep-alive
# 9 --- User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
# 10 --- 
# SENT ----- Port: 58168
# TRACKING LINES ----- Found port: 58184
# 13 - CONNECT manjaro.org:443 HTTP/1.1
# TRACKING FOR PORT 58184 ----- CONNECT manjaro.org:443 HTTP/1.1
# 14 - Host: manjaro.org:443
# TRACKING FOR PORT 58184 ----- Host: manjaro.org:443
# 15 - Proxy-Connection: keep-alive
# TRACKING FOR PORT 58184 ----- Proxy-Connection: keep-alive
# 16 - User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
# TRACKING FOR PORT 58184 ----- User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
# 17 - 
# TRACKING FOR PORT 58184 ----- 
# 18 - Ncat: Connection from ::1.
# 19 - Ncat: Connection from ::1:58192. !!!!!
# Port=
# 58184
# Body=
# 13 --- CONNECT manjaro.org:443 HTTP/1.1
# 14 --- Host: manjaro.org:443
# 15 --- Proxy-Connection: keep-alive
# 16 --- User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
# 17 --- 
# SENT ----- Port: 58184
# TRACKING LINES ----- Found port: 58192 !!!!!
# 20 - Ncat: Connection from ::1.
# 21 - Ncat: Connection from ::1:58196. !!!!!
# TRACKING LINES ----- Found port: 58196
# 22 - CONNECT manjaro.org:443 HTTP/1.1
# TRACKING FOR PORT 58196 ----- CONNECT manjaro.org:443 HTTP/1.1
# 23 - Host: manjaro.org:443
# TRACKING FOR PORT 58196 ----- Host: manjaro.org:443
# 24 - Proxy-Connection: keep-alive
# TRACKING FOR PORT 58196 ----- Proxy-Connection: keep-alive
# 25 - User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
# TRACKING FOR PORT 58196 ----- User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
# 26 - 
# TRACKING FOR PORT 58196 ----- 
# 27 - CONNECT cdnjs.cloudflare.com:443 HTTP/1.1
# TRACKING FOR PORT 58196 ----- CONNECT cdnjs.cloudflare.com:443 HTTP/1.1
# 28 - Host: cdnjs.cloudflare.com:443
# TRACKING FOR PORT 58196 ----- Host: cdnjs.cloudflare.com:443
# 29 - Proxy-Connection: keep-alive
# TRACKING FOR PORT 58196 ----- Proxy-Connection: keep-alive
# 30 - User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
# TRACKING FOR PORT 58196 ----- User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36
# 31 - 
# TRACKING FOR PORT 58196 ----- 