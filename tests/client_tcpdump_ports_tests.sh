#!/bin/bash

# tcpdump track ports used by chromium to send http requests into sendmail
mailport=30
tcpdump -nn -q -s 0 -t -l -i lo proto \\tcp and dst port 30 | grep -oP '(?<=\.)\d+(?=\s>)' --line-buffered >> /smtpsurfer/response/request_port.txt