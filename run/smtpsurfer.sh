#!/bin/bash

if [[ $1 == "run" ]]; 
then
    sudo mitmdump --mode upstream:http://localhost:60 --listen-host localhost --listen-port 30
    #python3 /smtpsurfer/python/client_browser-mail-browser_tunnel.py &
    bash /smtpsurfer/shell/client_browser-mail_tunnel.sh &
    bash /smtpsurfer/shell/client_mail-browser_tunnel.sh &
    sudo chromium --no-sandbox --proxy-server="localhost:30"
elif [[ $1 == "kill" ]]; 
then
    killall -9 $(ps aux | grep 'smtpsurfer' | awk '{print $2}')
    killall -9 ncat
    killall -9 nc
    #killall -9 socat
    killall -9 chromium
    killall -9 sendmail
    killall -9 python3
    killall -9 mitmdump
    chmod -R 777 /smtpsurfer
fi