#!/bin/bash

# BASIC MITM TO PROXY TEST
# connect client on mitmdump on port 30 and forward to proxy on port 8080
# on this setup mitmdump and the actual forward-proxy are on the same machine
# between mitmdump and proxy should be the mail-connetion in further steps
sudo mitmdump --mode upstream:http://localhost:8080 --listen-host localhost --listen-port 30

# STEP 1: CATCH TRAFFIC WITH SOCAT OR NCAT
# mitmdump will catch traffic with its cert to validate the connection
# socat or ncat will catch the traffic and from there it can be processed to sent via mail
sudo socat tcp-l:60,reuseaddr,fork - | cat
sudo ncat -klnp 60 | cat
sudo mitmdump --mode upstream:http://localhost:60 --listen-host localhost --listen-port 30

# TEST 1: MITMDUMP WITH RETURN PATH
# socat / ncat on port 30 has no return path
# dataflow: mitmdump receive client-data -> send to socat/ncat on port 60 (keep-alive with client)
# -> sendmail -> server get response on squid -> sendmail -> script handle mail -> send to socat/ncat on port 120
sudo mitmdump --mode upstream:http://localhost:60 --listen-host localhost --listen-port 30 | socat - tcp-l:120,reuseaddr,fork
